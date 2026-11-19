import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/client_usage_events.dart';
import '../ucg/data/ucg_feature_flags.dart';
import '../ui/prediction_wake_lock.dart';
import '../util/thinking_stage_delta.dart';
import '../voice/landscape_mic_permission.dart';
import '../voice/landscape_wake_word.dart';
import '../voice/voice_chat_ws_client.dart';
import 'client_usage_provider.dart';
import 'device_no_notifier.dart';
import 'voice_chat_ws_provider.dart';

/// 唤醒确认短「叮」（与开听并行，不再阻塞等人声「我在」）。
const kLandscapeDingAsset = 'audio/ding.wav';

/// 待唤醒时球旁 / 芯片文案。
const kLandscapeWakeHint = '说「胖宝」唤醒我';

/// 本地「我先退下了」提示音（对齐硬件 exit_dialog）。
const kLandscapeExitDialogAsset = 'audio/wo_xian_tui_xia_le.wav';

/// 横屏弹幕角色：思考态浅字+脉冲；状态字幕同样呼吸但不按静默清空。
enum LandscapeVoiceSubtitleKind {
  none,
  asr,
  thinking,
  answer,
  /// 唤醒确认与回合引导（我在 / 请说话 / 连接中）。
  status,
}

/// 横屏语音会话 UI 状态。
@immutable
class LandscapeVoiceUiState {
  const LandscapeVoiceUiState({
    this.listening = false,
    this.awakened = false,
    this.subtitle = '',
    this.subtitleKind = LandscapeVoiceSubtitleKind.none,
    this.statusCaption = kLandscapeWakeHint,
    this.thinking = '',
    this.micDenied = false,
    this.chatConnected = false,
    this.chatListening = false,
  });

  final bool listening;
  final bool awakened;
  final String subtitle;
  /// 当前弹幕语义角色（显式，禁止 UI 字符串猜测）。
  final LandscapeVoiceSubtitleKind subtitleKind;
  final String statusCaption;
  final String thinking;
  final bool micDenied;

  /// `/voice/chat/ws` 握手就绪。
  final bool chatConnected;

  /// 本轮正在上送用户 PCM（对齐 [VoiceChatWsClient.isListening]）。
  final bool chatListening;

  LandscapeVoiceUiState copyWith({
    bool? listening,
    bool? awakened,
    String? subtitle,
    LandscapeVoiceSubtitleKind? subtitleKind,
    String? statusCaption,
    String? thinking,
    bool? micDenied,
    bool? chatConnected,
    bool? chatListening,
  }) {
    return LandscapeVoiceUiState(
      listening: listening ?? this.listening,
      awakened: awakened ?? this.awakened,
      subtitle: subtitle ?? this.subtitle,
      subtitleKind: subtitleKind ?? this.subtitleKind,
      statusCaption: statusCaption ?? this.statusCaption,
      thinking: thinking ?? this.thinking,
      micDenied: micDenied ?? this.micDenied,
      chatConnected: chatConnected ?? this.chatConnected,
      chatListening: chatListening ?? this.chatListening,
    );
  }
}

/// 预测语音表面形态（横屏唤醒 vs 竖屏 FAB PTT）。
enum VoiceSurfaceMode {
  none,
  landscape,
  portraitPtt,
}

class LandscapeVoiceController extends Notifier<LandscapeVoiceUiState> {
  StreamSubscription<VoiceChatEvent>? _chatSub;
  StreamSubscription<bool>? _readySub;
  StreamSubscription<void>? _wakeSub;
  LandscapeWakeWord? _wake;
  var _active = false;
  var _turnBusy = false;
  var _exitInFlight = false;
  /// activate single-flight：防双 sync 重复冷启 KWS。
  Future<void>? _activateInFlight;
  /// deactivate 递增，取消进行中的 activate（ensureMic 之后勿再置 _active）。
  var _lifecycleGen = 0;
  /// lifecycle 表面 want：dn 晚到补激活仅在此为 true 时允许。
  var _surfaceWant = false;

  /// 当前表面：横屏 KWS 或竖屏预连 PTT。
  var _surfaceMode = VoiceSurfaceMode.none;

  /// 竖屏 FAB 按住说话中（松手前忽略服务端抢先 commit 业务收口）。
  var _holdActive = false;

  /// 手指仍希望 hold：松手/取消时先清，供 in-flight startHold 中途放弃。
  var _holdWanted = false;

  /// startHold single-flight：endHold 必须等其结束再 commit/取消。
  Future<bool>? _startHoldInFlight;

  /// 本轮 hold 已收到 TurnEnded（服务端抢先答完时松手不再二次 commit）。
  var _holdGotTurnEnded = false;

  /// 思考阶段已 resume KWS，可唤醒打断（TTS 播中必须关闭）。
  var _bargeInArmed = false;

  /// 回复 TTS 播放窗：禁止 barge-in / 芯片停播。
  var _ttsPlaybackActive = false;
  var _thinkingWakeHeld = false;

  /// 本轮开听是否已出现有效音（跨 soft rearm 保留）。
  var _heardEffectiveSpeech = false;

  Timer? _idleNoSpeechTimer;

  static const _micHandoffTimeout = Duration(seconds: 5);
  static const _micHandoffGap = Duration(milliseconds: 400);
  static const _afterExitResumeGap = Duration(milliseconds: 350);
  static const _idleNoSpeech = Duration(seconds: 5);

  @override
  LandscapeVoiceUiState build() {
    ref.onDispose(() {
      _cancelIdleNoSpeechTimer(reason: 'dispose');
      _subtitleIdleTimer?.cancel();
      unawaited(_tearDown());
    });
    // dn 空→有且表面仍 want、尚未激活：soft-check 补激活（冷启竞态）。
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      final prevDn = _normalizedDeviceNo(prev);
      final nextDn = _normalizedDeviceNo(next);
      final wasEmpty = prevDn == null || prevDn.isEmpty;
      final nowHas = nextDn != null && nextDn.isNotEmpty;
      if (!wasEmpty || !nowHas) return;
      if (!_surfaceWant || _active) return;
      AppDebugLog.landscapeVoice(
        'deviceNo arrived → re-activate mode=$_surfaceMode',
      );
      if (_surfaceMode == VoiceSurfaceMode.portraitPtt) {
        unawaited(activatePortraitPreconnect());
      } else {
        unawaited(activate(ensureMic: softCheckLandscapeMicGranted));
      }
    });
    return const LandscapeVoiceUiState();
  }

  bool get isPortraitPttMode => _surfaceMode == VoiceSurfaceMode.portraitPtt;
  bool get isHoldActive => _holdActive;

  /// 规范化 deviceNo；loading/error/空串视为无。
  static String? _normalizedDeviceNo(AsyncValue<String?>? v) {
    if (v == null) return null;
    final raw = v.asData?.value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// 由 [syncLandscapeVoiceLifecycle] 写入；离表面必须清 false。
  void setSurfaceWant(bool want) {
    _surfaceWant = want;
  }

  void _syncChatFlags() {
    final chat = ref.read(voiceChatWsClientProvider);
    state = state.copyWith(
      chatConnected: chat.isReady,
      chatListening: chat.isListening,
    );
  }

  /// 思考 / 回答字幕静默清空；状态字幕不走这只计时。
  Timer? _subtitleIdleTimer;

  static const _subtitleIdleClear = Duration(seconds: 3);

  /// 更新字幕并标注角色。思考与回答满 3 秒无变更则清空；状态字幕保留到被替换。
  void _setSubtitle(
    String text, {
    required LandscapeVoiceSubtitleKind kind,
  }) {
    _subtitleIdleTimer?.cancel();
    _subtitleIdleTimer = null;
    state = state.copyWith(subtitle: text, subtitleKind: kind);
    if (kind == LandscapeVoiceSubtitleKind.thinking ||
        kind == LandscapeVoiceSubtitleKind.answer) {
      final snapshot = text;
      _subtitleIdleTimer = Timer(_subtitleIdleClear, () {
        if (state.subtitle != snapshot || state.subtitleKind != kind) return;
        _clearSubtitle(reason: 'idle_3s');
      });
    }
  }

  /// 回合引导写到字幕并呼吸；球旁不再显示这句。
  void _setStatusSubtitle(String text) {
    _setSubtitle(text, kind: LandscapeVoiceSubtitleKind.status);
    state = state.copyWith(statusCaption: '');
  }

  /// 播完音频或本轮结束时清空弹幕。
  void _clearSubtitle({required String reason}) {
    _subtitleIdleTimer?.cancel();
    _subtitleIdleTimer = null;
    if (state.subtitle.isEmpty &&
        state.subtitleKind == LandscapeVoiceSubtitleKind.none) {
      return;
    }
    AppDebugLog.landscapeVoice('subtitle clear reason=$reason');
    state = state.copyWith(
      subtitle: '',
      subtitleKind: LandscapeVoiceSubtitleKind.none,
    );
  }

  /// 思考窗内不计静音退下。
  var _silenceExitSuspended = false;

  void _cancelIdleNoSpeechTimer({required String reason, bool quiet = false}) {
    if (_idleNoSpeechTimer != null && !quiet) {
      AppDebugLog.landscapeVoice('idle cancel reason=$reason');
    }
    _idleNoSpeechTimer?.cancel();
    _idleNoSpeechTimer = null;
  }

  /// 开听成功后武装 5s 静音退出。有效音用 [quiet] 重置，避免每块都打日志。
  void _armIdleNoSpeechTimer({bool quiet = false}) {
    _silenceExitSuspended = false;
    _cancelIdleNoSpeechTimer(reason: 'rearm', quiet: quiet);
    if (!quiet) {
      AppDebugLog.landscapeVoice('idle arm ${_idleNoSpeech.inSeconds}s');
    }
    _idleNoSpeechTimer = Timer(_idleNoSpeech, () {
      if (!_active || _exitInFlight || _silenceExitSuspended) return;
      AppDebugLog.landscapeVoice('idle fire');
      unawaited(_exitWithWoXianTuiXia());
    });
  }

  void _onEffectiveSpeechDetected() {
    _heardEffectiveSpeech = true;
    // 思考中或麦已停：不把静音窗重新打开。
    if (_silenceExitSuspended || _exitInFlight) return;
    final chat = ref.read(voiceChatWsClientProvider);
    if (!chat.isListening) return;
    _armIdleNoSpeechTimer(quiet: true);
  }

  /// 预测**横屏**表面可见时调用；[ensureMic] 由调用方注入 soft-check 或完整申请。
  Future<void> activate({
    required Future<bool> Function() ensureMic,
  }) async {
    // 须在改 mode 前读取：竖屏预连也会把 _active 置真，不能早退跳过 KWS。
    final fromPortrait = _surfaceMode == VoiceSurfaceMode.portraitPtt;
    _holdWanted = false;
    _holdActive = false;
    _holdGotTurnEnded = false;
    ref.read(voiceChatWsClientProvider).setHoldUplinkProtected(false);
    _surfaceMode = VoiceSurfaceMode.landscape;
    if (kIsWeb) return;

    // 已是横屏且 KWS 在：幂等。
    if (_active && !fromPortrait && _wake != null) {
      return;
    }

    // 从竖屏 PTT 切来（或 _active 但无 wake）：补挂 KWS，勿整段 deactivate。
    if (_active && (fromPortrait || _wake == null)) {
      AppDebugLog.landscapeVoice(
        'activate rebind landscape fromPortrait=$fromPortrait '
        'wakeNull=${_wake == null}',
      );
      final existing = _activateInFlight;
      if (existing != null) {
        try {
          await existing;
        } catch (_) {}
      }
      final gen = _lifecycleGen;
      final micOk = await ensureMic();
      if (gen != _lifecycleGen || !_active) return;
      if (!micOk) {
        AppDebugLog.landscapeVoice('activate rebind soft mic pending');
        state = state.copyWith(
          listening: false,
          micDenied: true,
          statusCaption: '需要麦克风权限才能语音唤醒（点按重试）',
        );
        return;
      }
      state = state.copyWith(micDenied: false);
      await _attachWakeListening(gen: gen);
      return;
    }

    final existing = _activateInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final flight = _activateBody(ensureMic: ensureMic);
    _activateInFlight = flight;
    try {
      await flight;
    } finally {
      if (identical(_activateInFlight, flight)) {
        _activateInFlight = null;
      }
    }
  }

  Future<void> _activateBody({
    required Future<bool> Function() ensureMic,
  }) async {
    if (_active) return;
    final gen = _lifecycleGen;

    final dn = _normalizedDeviceNo(ref.read(deviceNoNotifierProvider));
    if (dn == null) {
      state = state.copyWith(
        statusCaption: '绑定宝宝后可语音完成喂养记录',
        micDenied: false,
        chatConnected: false,
        chatListening: false,
      );
      return;
    }

    // soft-check 失败 = 尚未授权（不置会话拒绝）；仍半激活并预连 chat WS。
    final micOk = await ensureMic();
    if (gen != _lifecycleGen) return;

    _active = true;
    if (!micOk) {
      AppDebugLog.landscapeVoice('activate soft mic pending');
      state = state.copyWith(
        listening: false,
        micDenied: true,
        statusCaption: '需要麦克风权限才能语音唤醒（点按重试）',
      );
      _bindChatSession();
      return;
    }

    state = state.copyWith(micDenied: false);
    _bindChatSession();
    await _attachWakeListening(gen: gen);
  }

  /// 绑定 chat 事件并预连 `/voice/chat/ws`（可无麦）。
  void _bindChatSession() {
    final chat = ref.read(voiceChatWsClientProvider);
    _chatSub?.cancel();
    _chatSub = chat.events.listen(_onChatEvent);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    chat.onBeforeTtsPlay = _onBeforeTtsPlay;
    chat.onTtsStoppedByLifecycle = () {
      _ttsPlaybackActive = false;
      unawaited(_setThinkingWake(false));
      if (!_active || _turnBusy) return;
      unawaited(_finishTurn(endReason: 'app_pause'));
    };
    _readySub?.cancel();
    _readySub = chat.readyStream.listen((ready) {
      if (!_active) return;
      AppDebugLog.landscapeVoice('ready=$ready');
      state = state.copyWith(
        chatConnected: ready,
        chatListening: ready ? chat.isListening : false,
      );
    });
    unawaited(chat.connect().then((ok) {
      if (!_active) return;
      AppDebugLog.landscapeVoice('connect ok=$ok');
      _syncChatFlags();
      if (!ok && state.micDenied) {
        // 无麦半激活：保留点按授权文案，不覆盖成连接中。
        return;
      }
      if (!ok) {
        state = state.copyWith(statusCaption: '语音通道连接中…可稍后再试');
      }
    }));
  }

  /// 已授权后启动 / 补启本地唤醒监听。
  Future<void> _attachWakeListening({required int gen}) async {
    _wake ??= createLandscapeWakeWord();
    _wakeSub?.cancel();
    _wakeSub = _wake!.detections.listen((_) {
      unawaited(_onWakeDetection());
    });
    final wakeOk = await _wake!.start(
      onStatus: (s) {
        if (_active) state = state.copyWith(statusCaption: s);
      },
    );
    if (gen != _lifecycleGen || !_active) return;
    _syncChatFlags();
    state = state.copyWith(
      listening: wakeOk,
      micDenied: false,
      statusCaption: wakeOk
          ? kLandscapeWakeHint
          : (_wake!.unavailableReason ?? '唤醒未就绪'),
    );
  }

  /// 用户点按后完整申请麦权；半激活时补启 KWS，未激活则带已授权 ensure 走 activate。
  Future<void> _requestMicAndArmWake(BuildContext context) async {
    landscapeMicDeniedThisSession = false;
    final ok = await ensureLandscapeMicPermission(context);
    if (!context.mounted) return;
    if (!ok) {
      state = state.copyWith(
        listening: false,
        micDenied: true,
        statusCaption: '需要麦克风权限才能语音唤醒（点按重试）',
      );
      return;
    }
    if (!_active) {
      await activate(ensureMic: () async => true);
      return;
    }
    AppDebugLog.landscapeVoice('chip mic granted → attach wake');
    state = state.copyWith(micDenied: false);
    await _attachWakeListening(gen: _lifecycleGen);
  }

  /// 预测**竖屏**表面：只预连 chat WS，不启 KWS、不开麦。
  Future<void> activatePortraitPreconnect() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    _surfaceMode = VoiceSurfaceMode.portraitPtt;
    final existing = _activateInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final flight = _activatePortraitBody();
    _activateInFlight = flight;
    try {
      await flight;
    } finally {
      if (identical(_activateInFlight, flight)) {
        _activateInFlight = null;
      }
    }
  }

  Future<void> _activatePortraitBody() async {
    final gen = _lifecycleGen;
    final dn = _normalizedDeviceNo(ref.read(deviceNoNotifierProvider));
    if (dn == null || dn.isEmpty) {
      AppDebugLog.landscapeVoice('portrait preconnect no deviceNo');
      _active = false;
      state = state.copyWith(
        listening: false,
        chatConnected: false,
        chatListening: false,
        statusCaption: '绑定宝宝后可长按语音记录',
      );
      return;
    }
    if (gen != _lifecycleGen) return;
    // 若从横屏切来，先拆 KWS。
    await _wakeSub?.cancel();
    _wakeSub = null;
    await _wake?.stop();
    _wake = null;
    _active = true;
    _holdWanted = false;
    _holdActive = false;
    _holdGotTurnEnded = false;
    ref.read(voiceChatWsClientProvider).setHoldUplinkProtected(false);
    state = state.copyWith(
      listening: false,
      awakened: false,
      micDenied: false,
      statusCaption: '',
    );
    _bindChatSession();
    AppDebugLog.landscapeVoice('portrait preconnect bound');
  }

  /// 竖屏 FAB 长按开始 PTT：ding + text 模态开听。
  ///
  /// 与 [endHold] 通过 [_holdWanted] / [_startHoldInFlight] 协调：
  /// 松手早于开麦完成时，取消则中途放弃；发送则等开麦成功再 commit。
  Future<bool> startHold(BuildContext context) async {
    if (kIsWeb) return false;
    if (_surfaceMode != VoiceSurfaceMode.portraitPtt) {
      AppDebugLog.landscapeVoice('startHold skip not portraitPtt');
      return false;
    }
    // 已有 in-flight：复用同一 Future，避免双开麦。
    final inflight = _startHoldInFlight;
    if (inflight != null) {
      AppDebugLog.landscapeVoice('startHold join inflight');
      return inflight;
    }
    if (_holdActive) return true;

    _holdWanted = true;
    final fut = _startHoldBody(context);
    _startHoldInFlight = fut;
    try {
      return await fut;
    } finally {
      if (identical(_startHoldInFlight, fut)) {
        _startHoldInFlight = null;
      }
    }
  }

  Future<bool> _startHoldBody(BuildContext context) async {
    if (!_active) {
      await activatePortraitPreconnect();
    }
    if (!_holdWanted) {
      AppDebugLog.landscapeVoice('hold abort after preconnect');
      return false;
    }
    if (!_active) {
      AppDebugLog.landscapeVoice('hold abort inactive (need deviceNo?)');
      _setStatusSubtitle('绑定宝宝后可长按语音记录');
      return false;
    }
    if (!context.mounted) {
      AppDebugLog.landscapeVoice('hold abort context unmounted');
      return false;
    }

    final micOk = await ensureLandscapeMicPermission(context);
    if (!_holdWanted) {
      AppDebugLog.landscapeVoice('hold abort after mic perm');
      return false;
    }
    if (!context.mounted) {
      AppDebugLog.landscapeVoice('hold abort context after mic');
      return false;
    }
    if (!micOk) {
      AppDebugLog.landscapeVoice('hold abort micDenied');
      state = state.copyWith(
        micDenied: true,
        statusCaption: '需要麦克风权限才能语音记录',
      );
      _setStatusSubtitle('需要麦克风权限');
      return false;
    }
    state = state.copyWith(micDenied: false);

    _holdActive = true;
    _holdGotTurnEnded = false;
    _turnBusy = true;
    _cancelIdleNoSpeechTimer(reason: 'hold_start');
    _setStatusSubtitle('正在接通…');
    state = state.copyWith(awakened: true, thinking: '');

    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = null;
    // 开听前即保护：避免短暂静音帧抢停麦。
    chat.setHoldUplinkProtected(true);
    try {
      // 先开麦再 ding，缩短「手指已按住但上行未起」窗口。
      AppDebugLog.landscapeVoice('hold step=beginListen text');
      final ok = await chat
          .beginListen(
            resetEffectiveSpeech: true,
            outputModality: 'text',
          )
          .timeout(_micHandoffTimeout);
      if (!_holdWanted || !_active) {
        AppDebugLog.landscapeVoice('hold abort after beginListen');
        chat.setHoldUplinkProtected(false);
        await chat.ensureMicStopped();
        await chat.endSession(reason: 'hold_abort');
        _holdActive = false;
        _turnBusy = false;
        _clearSubtitle(reason: 'hold_abort');
        state = state.copyWith(awakened: false, chatListening: false);
        _syncChatFlags();
        return false;
      }
      if (!ok) {
        chat.setHoldUplinkProtected(false);
        _holdActive = false;
        _turnBusy = false;
        _setStatusSubtitle('无法开麦，请再试');
        return false;
      }
      _syncChatFlags();
      _setStatusSubtitle('请说话…');
      state = state.copyWith(
        chatListening: true,
        chatConnected: chat.isReady,
      );
      _turnBusy = false;
      // 竖屏 PTT：开流后禁止并行 ding（Vivo 上 MediaPlayer 会弄脏 AudioRecord → 零 PCM）。
      AppDebugLog.landscapeVoice('hold step=listening no_ding');
      return true;
    } on TimeoutException {
      chat.setHoldUplinkProtected(false);
      _holdActive = false;
      _turnBusy = false;
      _holdWanted = false;
      _setStatusSubtitle('开麦超时，请再试');
      return false;
    } catch (e) {
      AppDebugLog.landscapeVoice('hold start err=$e');
      chat.setHoldUplinkProtected(false);
      _holdActive = false;
      _turnBusy = false;
      _holdWanted = false;
      _setStatusSubtitle('启动失败，请再试');
      return false;
    }
  }

  /// 竖屏 FAB 松手：keep 区内 commit；取消则停麦不 commit。无退场音。
  ///
  /// 若 [startHold] 仍在飞：取消会清 [_holdWanted] 令其放弃；发送则等开麦成功再 commit。
  Future<void> endHold({required bool cancel}) async {
    AppDebugLog.landscapeVoice(
      'endHold cancel=$cancel active=$_holdActive '
      'inflight=${_startHoldInFlight != null} gotEnded=$_holdGotTurnEnded',
    );

    final inflight = _startHoldInFlight;
    if (cancel) {
      // 先打断 in-flight，再收口。
      _holdWanted = false;
      if (inflight != null) {
        try {
          await inflight;
        } catch (_) {}
      }
    } else if (inflight != null) {
      // 发送：保持 wanted，等开麦完成后再 commit。
      AppDebugLog.landscapeVoice('endHold await startHold for commit');
      final started = await inflight;
      if (!started) {
        AppDebugLog.landscapeVoice('endHold commit skipped startFail');
        _holdWanted = false;
        return;
      }
    }

    if (!_holdActive && !_holdGotTurnEnded) {
      AppDebugLog.landscapeVoice('endHold noop hold=false cancel=$cancel');
      _holdWanted = false;
      ref.read(voiceChatWsClientProvider).setHoldUplinkProtected(false);
      return;
    }

    final wasHolding = _holdActive;
    _holdActive = false;
    _holdWanted = false;
    final chat = ref.read(voiceChatWsClientProvider);
    // 松手后允许服务端帧停麦；client commit/cancel 显式停麦。
    chat.setHoldUplinkProtected(false);
    if (cancel) {
      await chat.ensureMicStopped();
      await chat.endSession(reason: 'hold_cancel');
      _holdGotTurnEnded = false;
      _turnBusy = false;
      _clearSubtitle(reason: 'hold_cancel');
      state = state.copyWith(
        awakened: false,
        chatListening: false,
        thinking: '',
        statusCaption: '',
      );
      _syncChatFlags();
      return;
    }
    // 已有答复：不再二次 commit，只收尾会话窗。
    if (_holdGotTurnEnded) {
      await chat.ensureMicStopped();
      await chat.endSession(reason: 'hold_done');
      _holdGotTurnEnded = false;
      _turnBusy = false;
      state = state.copyWith(
        awakened: false,
        chatListening: false,
      );
      _syncChatFlags();
      return;
    }
    if (!wasHolding) return;
    state = state.copyWith(chatListening: false);
    _setStatusSubtitle('识别中…');
    await chat.commitUtterance();
    _syncChatFlags();
  }

  /// 按住期间若麦已异常停掉：提示并尝试一次续听，禁止继续伪装「请说话…」。
  Future<void> _rearmHoldUplinkIfDead() async {
    if (!_holdActive || !_holdWanted) return;
    final chat = ref.read(voiceChatWsClientProvider);
    if (chat.isListening) {
      // 与真实上行对齐 UI。
      if (!state.chatListening) {
        state = state.copyWith(chatListening: true);
      }
      return;
    }
    AppDebugLog.landscapeVoice('hold mic dead → try rearm');
    _setStatusSubtitle('重新开麦…');
    state = state.copyWith(chatListening: false);
    try {
      final ok = await chat.beginListen(
        resetEffectiveSpeech: false,
        outputModality: 'text',
      );
      if (!_holdActive || !_holdWanted) return;
      if (!ok) {
        _setStatusSubtitle('开麦中断，请重按');
        state = state.copyWith(chatListening: false);
        return;
      }
      _syncChatFlags();
      _setStatusSubtitle('请说话…');
      state = state.copyWith(chatListening: true);
      AppDebugLog.landscapeVoice('hold mic rearmed');
    } catch (e) {
      AppDebugLog.landscapeVoice('hold mic rearm err=$e');
      if (_holdActive) {
        _setStatusSubtitle('开麦中断，请重按');
        state = state.copyWith(chatListening: false);
      }
    }
  }

  Future<void> deactivate() async {
    _surfaceWant = false;
    _lifecycleGen++;
    _active = false;
    _holdWanted = false;
    _holdActive = false;
    _holdGotTurnEnded = false;
    _cancelIdleNoSpeechTimer(reason: 'deactivate');
    final inflight = _activateInFlight;
    if (inflight != null) {
      try {
        await inflight;
      } catch (_) {}
    }
    await _tearDown();
    _surfaceMode = VoiceSurfaceMode.none;
    state = const LandscapeVoiceUiState();
  }

  Future<void> _tearDown() async {
    _cancelIdleNoSpeechTimer(reason: 'teardown');
    _holdWanted = false;
    _holdActive = false;
    _holdGotTurnEnded = false;
    await _wakeSub?.cancel();
    _wakeSub = null;
    await _wake?.stop();
    _wake = null;
    await _chatSub?.cancel();
    _chatSub = null;
    await _readySub?.cancel();
    _readySub = null;
    final chat = ref.read(voiceChatWsClientProvider);
    chat.setHoldUplinkProtected(false);
    chat.onEffectiveSpeech = null;
    chat.onBeforeTtsPlay = null;
    chat.onTtsStoppedByLifecycle = null;
    await chat.endSession(reason: 'teardown');
    await chat.disconnect();
    _turnBusy = false;
    _exitInFlight = false;
    _heardEffectiveSpeech = false;
    _bargeInArmed = false;
    _ttsPlaybackActive = false;
    await _setThinkingWake(false);
  }

  Future<void> _setThinkingWake(bool hold) async {
    if (_thinkingWakeHeld == hold) return;
    _thinkingWakeHeld = hold;
    await PredictionWakeLock.setThinking(hold);
  }

  void _disarmBargeIn({required String reason}) {
    if (!_bargeInArmed) return;
    _bargeInArmed = false;
    AppDebugLog.landscapeVoice('bargeIn disarm reason=$reason');
  }

  /// TTS 开播前：释放思考常亮与 KWS 麦。播放期间不计静音退下。
  Future<void> _onBeforeTtsPlay() async {
    _ttsPlaybackActive = true;
    _bargeInArmed = false;
    _silenceExitSuspended = true;
    _cancelIdleNoSpeechTimer(reason: 'tts');
    unawaited(_setThinkingWake(false));
    AppDebugLog.landscapeVoice('bargeIn disarm reason=tts_start');
    try {
      await _wake?.pause().timeout(_micHandoffTimeout);
    } catch (e) {
      AppDebugLog.landscapeVoice('bargeIn pause tts_start err=$e');
    }
  }

  /// 思考窗：停上行麦后 resume KWS，供再说唤醒词打断（播中禁止）。
  Future<void> _armBargeInWake() async {
    if (!_active || _exitInFlight) return;
    if (_ttsPlaybackActive) {
      AppDebugLog.landscapeVoice('bargeIn arm skip tts_playing');
      return;
    }
    final chat = ref.read(voiceChatWsClientProvider);
    if (chat.isListening) return;
    if (!state.awakened) return;

    await chat.ensureMicStopped();
    await Future<void>.delayed(_afterExitResumeGap);
    if (!_active ||
        _exitInFlight ||
        chat.isListening ||
        !state.awakened ||
        _ttsPlaybackActive) {
      return;
    }

    _bargeInArmed = true;
    AppDebugLog.landscapeVoice('bargeIn arm');
    final wake = _wake;
    if (wake == null) return;

    var ok = await wake.resume();
    if (!ok && _active) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      ok = await wake.resume();
    }
    if (!ok && _active) {
      ok = await wake.start(
        onStatus: (s) {
          if (_active) state = state.copyWith(statusCaption: s);
        },
      );
    }
    // 若 arm 过程中已开播 TTS：立刻交还麦
    if (!_active || !_bargeInArmed || _ttsPlaybackActive) {
      if (_ttsPlaybackActive) {
        _bargeInArmed = false;
        try {
          await wake.pause().timeout(_micHandoffTimeout);
        } catch (_) {}
        AppDebugLog.landscapeVoice('bargeIn arm aborted tts_playing');
      }
      return;
    }
    if (ok) {
      state = state.copyWith(listening: true);
      AppDebugLog.landscapeVoice('bargeIn arm ok');
    } else {
      _disarmBargeIn(reason: 'arm_fail');
      AppDebugLog.landscapeVoice('bargeIn arm fail');
    }
  }

  Future<void> _failWakeStart(String caption) async {
    AppDebugLog.landscapeVoice('wake start fail caption=$caption');
    _cancelIdleNoSpeechTimer(reason: 'wake_fail');
    _disarmBargeIn(reason: 'wake_fail');
    _heardEffectiveSpeech = false;
    _clearSubtitle(reason: 'wake_fail');
    state = state.copyWith(
      statusCaption: caption,
      awakened: false,
      chatListening: false,
    );
    _turnBusy = false;
    // 开听失败：若已 start 也发 end，再交还 KWS。
    final chat = ref.read(voiceChatWsClientProvider);
    await chat.endSession(reason: 'wake_fail');
    await _restoreWakeListening(statusIfOk: caption);
  }

  /// 习惯上报：fire-and-forget，宁丢点不堵开听。
  void _reportVoiceUsage(ClientUsageEvent event) {
    unawaited(ref.read(clientUsageReporterProvider).reportEvent(event));
  }

  /// 检测分流：对话段内 barge-in vs 待唤醒普通唤醒。
  /// [fromTap] true=监听 chip / 竖屏贴边球点击开听。
  Future<void> _onWakeDetection({bool fromTap = false}) async {
    if (!_active) return;
    // 播中禁止打断（含残留 armed）
    if (_ttsPlaybackActive) {
      AppDebugLog.landscapeVoice('wake ignore tts_playing');
      return;
    }
    if (_bargeInArmed && state.awakened) {
      await _onBargeInWake();
      return;
    }
    // 汇合前分报：KWS vs 点击。
    _reportVoiceUsage(
      fromTap
          ? ClientUsageEvents.voiceWakeTap
          : ClientUsageEvents.voiceWakeKws,
    );
    await _onWake();
  }

  /// 思考窗再说唤醒词：停后续 TTS → end →「我在」→ 开听。播放中不得进入。
  Future<void> _onBargeInWake() async {
    if (!_active || _turnBusy) return;
    if (_ttsPlaybackActive) {
      AppDebugLog.landscapeVoice('bargeIn ignore tts_playing');
      return;
    }
    // 独立事件：打断思考习惯。
    _reportVoiceUsage(ClientUsageEvents.voiceWakeBargeIn);
    _turnBusy = true;
    _disarmBargeIn(reason: 'hit');
    _exitInFlight = false;
    _heardEffectiveSpeech = false;
    _ttsPlaybackActive = false;
    unawaited(_setThinkingWake(false));
    _cancelIdleNoSpeechTimer(reason: 'barge_in');
    AppDebugLog.landscapeVoice('bargeIn hit');

    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    try {
      await chat.stopTts();
      await chat.endSession(reason: 'wake_barge_in');
      // 字幕「我在」；叮与开听并行，不等播完。
      _setStatusSubtitle('我在');
      state = state.copyWith(
        awakened: true,
        thinking: '',
        chatListening: false,
      );

      AppDebugLog.landscapeVoice('bargeIn step=pause');
      await _wake?.pause().timeout(_micHandoffTimeout);
      await Future<void>.delayed(_micHandoffGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      AppDebugLog.landscapeVoice('bargeIn step=play_ding');
      unawaited(chat.playAssetWav(kLandscapeDingAsset));
      _setStatusSubtitle('正在接通会话…');
      AppDebugLog.landscapeVoice('bargeIn step=beginListen audio');
      final ok = await chat
          .beginListen(outputModality: 'audio')
          .timeout(_micHandoffTimeout);
      if (!_active) {
        _turnBusy = false;
        return;
      }
      if (!ok) {
        await _failWakeStart('无法开始聆听');
        return;
      }
      _syncChatFlags();
      _setStatusSubtitle('请说话…');
      state = state.copyWith(
        chatListening: true,
        chatConnected: chat.isReady,
        awakened: true,
      );
      _turnBusy = false;
      _armIdleNoSpeechTimer();
      AppDebugLog.landscapeVoice('bargeIn step=listening');
    } on TimeoutException {
      await _failWakeStart('开麦超时，请再试');
    } catch (e) {
      AppDebugLog.landscapeVoice('bargeIn err=$e');
      await _failWakeStart('打断后启动失败');
    }
  }

  Future<void> _onWake() async {
    if (!_active || _turnBusy) return;
    _turnBusy = true;
    _disarmBargeIn(reason: 'normal_wake');
    _exitInFlight = false;
    _heardEffectiveSpeech = false;
    _cancelIdleNoSpeechTimer(reason: 'wake');
    _setStatusSubtitle('我在');
    state = state.copyWith(
      awakened: true,
      thinking: '',
    );
    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    try {
      AppDebugLog.landscapeVoice('wake step=pause');
      await _wake?.pause().timeout(_micHandoffTimeout);
      await Future<void>.delayed(_micHandoffGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      AppDebugLog.landscapeVoice('wake step=play_ding');
      unawaited(chat.playAssetWav(kLandscapeDingAsset));
      _setStatusSubtitle('正在接通会话…');
      AppDebugLog.landscapeVoice('wake step=beginListen audio');
      final ok = await chat
          .beginListen(outputModality: 'audio')
          .timeout(_micHandoffTimeout);
      if (!_active) {
        _turnBusy = false;
        return;
      }
      if (!ok) {
        await _failWakeStart('无法开始聆听');
        return;
      }
      _syncChatFlags();
      _setStatusSubtitle('请说话…');
      state = state.copyWith(
        chatListening: true,
        chatConnected: chat.isReady,
      );
      // 开听已武装：收窄忙锁，允许芯片恢复。
      _turnBusy = false;
      _armIdleNoSpeechTimer();
      AppDebugLog.landscapeVoice('wake step=listening');
    } on TimeoutException {
      await _failWakeStart('开麦超时，请再试');
    } catch (e) {
      AppDebugLog.landscapeVoice('wake start err=$e');
      await _failWakeStart('唤醒后启动失败');
    }
  }

  void _onChatEvent(VoiceChatEvent e) {
    switch (e) {
      case VoiceChatAsrPartial(:final text):
        _setSubtitle(text, kind: LandscapeVoiceSubtitleKind.asr);
      case VoiceChatAsrFinal(:final text):
        _setSubtitle(text, kind: LandscapeVoiceSubtitleKind.asr);
        // 仅用户句截断上报；空串跳过；不 await。
        final user = text.trim();
        if (user.isNotEmpty) {
          _reportVoiceUsage(ClientUsageEvents.voiceTurnUser(user));
        }
      case VoiceChatThinkingDelta(:final delta):
        // 按 \r 分阶段展示思考，避免弹幕堆长文。
        final next = applyThinkingStageDelta(state.thinking, delta);
        state = state.copyWith(thinking: next);
        _setSubtitle(next, kind: LandscapeVoiceSubtitleKind.thinking);
      case VoiceChatAnswer(:final text):
        state = state.copyWith(thinking: '');
        _setSubtitle(text, kind: LandscapeVoiceSubtitleKind.answer);
      case VoiceChatInterruptCommit():
        // 竖屏按住：忽略抢先 commit；门闩下麦仍开，保持聆听 UI。
        if (_holdActive) {
          AppDebugLog.landscapeVoice('hold ignore interrupt_commit keep mic');
          _syncChatFlags();
          unawaited(_rearmHoldUplinkIfDead());
          return;
        }
        state = state.copyWith(chatListening: false);
        // 竖屏松手后的 commit：只停麦示意，不武装横屏 barge-in KWS。
        if (_surfaceMode == VoiceSurfaceMode.portraitPtt) {
          _syncChatFlags();
          if (_heardEffectiveSpeech || state.subtitle.isNotEmpty) {
            state = state.copyWith(statusCaption: '');
            _setStatusSubtitle('思考中…');
          }
          return;
        }
        unawaited(_afterServerCommit());
      case VoiceChatTurnEnded(:final ok, :final message, :final finishTalk):
        _ttsPlaybackActive = false;
        // 竖屏 PTT：按住期间只记结果；松手后也不自动续听。
        if (_surfaceMode == VoiceSurfaceMode.portraitPtt) {
          if (!ok && message == 'asr_no_result') {
            if (_holdActive) {
              // 勿置 _holdGotTurnEnded，否则松手会跳过 client commit。
              AppDebugLog.landscapeVoice(
                'hold asr_no_result while holding ignore',
              );
              unawaited(_rearmHoldUplinkIfDead());
              return;
            }
            _holdGotTurnEnded = true;
            _setStatusSubtitle('没听清，请再按住说');
            state = state.copyWith(awakened: false, chatListening: false);
            return;
          }
          _holdGotTurnEnded = true;
          if (!ok && (message != null && message.isNotEmpty)) {
            state = state.copyWith(statusCaption: message);
          }
          // 保留 answer 字幕；不走横屏 idle/KWS 收尾。
          if (!_holdActive) {
            state = state.copyWith(
              awakened: false,
              chatListening: false,
              thinking: '',
            );
            _syncChatFlags();
          }
          AppDebugLog.landscapeVoice(
            'hold TurnEnded ok=$ok finishTalk=$finishTalk holding=$_holdActive',
          );
          return;
        }
        if (!ok && message == 'asr_no_result') {
          unawaited(_onAsrNoResult());
          return;
        }
        if (!ok && (message != null && message.isNotEmpty)) {
          // 失败短因走左下角；弹幕跟播完清，无 TTS 则本轮结束清。
          state = state.copyWith(statusCaption: message);
        }
        // 成功路径：client 已在 TTS 播完后才发 TurnEnded。
        _clearSubtitle(reason: ok ? 'tts_done' : 'turn_ended');
        if (ok && !finishTalk) {
          // 服务端要求续聊：同连接 end→start→开听，不回 KWS。
          unawaited(_continueListenAfterServer());
        } else {
          unawaited(_finishTurn(endReason: ok ? 'finish_talk' : 'turn_fail'));
        }
      case VoiceChatExit():
        _ttsPlaybackActive = false;
        _clearSubtitle(reason: 'exit_event');
        if (_surfaceMode == VoiceSurfaceMode.portraitPtt) {
          _holdActive = false;
          _holdGotTurnEnded = false;
          state = state.copyWith(awakened: false, chatListening: false);
          return;
        }
        // client 已在 exit 路径发过 end。
        unawaited(_finishTurn(endReason: 'exit', alreadyEnded: true));
    }
  }

  /// finish_talk=false：续听并重武装 5s idle；先 pause barge-in KWS。
  Future<void> _continueListenAfterServer() async {
    if (!_active || _exitInFlight) return;
    AppDebugLog.landscapeVoice('continueListen after finish_talk=false');
    _disarmBargeIn(reason: 'continue_listen');
    _heardEffectiveSpeech = false;
    _cancelIdleNoSpeechTimer(reason: 'continue');
    _setStatusSubtitle('请说话…');
    state = state.copyWith(
      thinking: '',
      awakened: true,
      chatListening: false,
    );
    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    try {
      // 续听独占麦：交还前若 KWS 在跑则 pause
      await _wake?.pause().timeout(_micHandoffTimeout);
      await Future<void>.delayed(_micHandoffGap);
    } catch (e) {
      AppDebugLog.landscapeVoice('continueListen pause err=$e');
    }
    if (!_active || _exitInFlight) return;
    final ok = await chat.beginListen(
      resetEffectiveSpeech: true,
      outputModality: 'audio',
    );
    if (!_active || _exitInFlight) return;
    if (!ok) {
      AppDebugLog.landscapeVoice('continueListen beginListen fail');
      await _exitWithWoXianTuiXia();
      return;
    }
    _turnBusy = false;
    _syncChatFlags();
    _setStatusSubtitle('请说话…');
    state = state.copyWith(
      chatListening: true,
      awakened: true,
    );
    _armIdleNoSpeechTimer();
  }

  Future<void> _onAsrNoResult() async {
    final chat = ref.read(voiceChatWsClientProvider);
    _disarmBargeIn(reason: 'asr_no_result');
    // 已有有效音：空片段续听，不整轮退下。
    if (_heardEffectiveSpeech || chat.hasEffectiveSpeech) {
      _heardEffectiveSpeech = true;
      unawaited(_setThinkingWake(false));
      _cancelIdleNoSpeechTimer(reason: 'no_result_soft');
      AppDebugLog.landscapeVoice('asr_no_result soft rearm');
      try {
        await _wake?.pause().timeout(_micHandoffTimeout);
        await Future<void>.delayed(_micHandoffGap);
      } catch (_) {}
      final ok = await chat.beginListen(
        resetEffectiveSpeech: false,
        outputModality: 'audio',
      );
      if (!_active || _exitInFlight) return;
      if (ok) {
        _turnBusy = false;
        _syncChatFlags();
        _setStatusSubtitle('请说话…');
        state = state.copyWith(
          chatListening: true,
          awakened: true,
        );
        // 空片段不是退下；续听后静音窗重新从 5 秒起算。
        _armIdleNoSpeechTimer();
      } else {
        AppDebugLog.landscapeVoice('soft rearm fail');
        await _exitWithWoXianTuiXia();
      }
      return;
    }
    // 尚无有效音：麦已被停，续听等待 5s 无声终局（不重置 idle）。
    AppDebugLog.landscapeVoice('asr_no_result ignored awaiting idle');
    final ok = await chat.beginListen(
      resetEffectiveSpeech: false,
      outputModality: 'audio',
    );
    if (!_active || _exitInFlight) return;
    if (ok) {
      _turnBusy = false;
      _syncChatFlags();
      _setStatusSubtitle('请说话…');
      state = state.copyWith(
        chatListening: true,
        awakened: true,
      );
      if (_idleNoSpeechTimer == null) {
        _armIdleNoSpeechTimer();
      }
    } else {
      await _exitWithWoXianTuiXia();
    }
  }

  Future<void> _exitWithWoXianTuiXia() async {
    if (_exitInFlight) return;
    _exitInFlight = true;
    _cancelIdleNoSpeechTimer(reason: 'exit');
    AppDebugLog.landscapeVoice('exit wo_xian_tui_xia_le');
    _heardEffectiveSpeech = false;
    state = state.copyWith(
      statusCaption: '我先退下了',
      chatListening: false,
    );
    _setSubtitle('我先退下了', kind: LandscapeVoiceSubtitleKind.asr);
    final chat = ref.read(voiceChatWsClientProvider);
    try {
      await chat.ensureMicStopped();
      // idle / 主动退下：MUST end，清服务端会话窗。
      AppDebugLog.landscapeVoice('idle_exit end');
      await chat.endSession(reason: 'idle_exit');
      await chat.playAssetWav(kLandscapeExitDialogAsset);
      _clearSubtitle(reason: 'exit_prompt_done');
    } catch (e) {
      AppDebugLog.landscapeVoice('exit prompt play err=$e');
      _clearSubtitle(reason: 'exit_prompt_err');
    }
    if (!_active) {
      _turnBusy = false;
      _exitInFlight = false;
      return;
    }
    await _finishTurn(endReason: 'idle_exit', alreadyEnded: true);
    _exitInFlight = false;
  }

  Future<void> _afterServerCommit() async {
    // 服务端已 interrupt_commit：麦克已停，等待 TTS/结束事件。
    // 有转写时会走 thinking；空结果随后 asr_no_result 续听。
    if (_heardEffectiveSpeech) {
      state = state.copyWith(
        statusCaption: '思考中…',
        chatListening: false,
      );
    } else {
      _setStatusSubtitle('请说话…');
      state = state.copyWith(chatListening: false);
    }
    _syncChatFlags();
    // 思考窗不计静音；空结果随后 asr_no_result 再武装。
    if (_heardEffectiveSpeech) {
      _silenceExitSuspended = true;
      _cancelIdleNoSpeechTimer(reason: 'thinking');
      unawaited(_setThinkingWake(true));
      unawaited(_armBargeInWake());
    }
  }

  /// 结束本段并回唤醒；[alreadyEnded] 时跳过再发 end。
  Future<void> _finishTurn({
    String endReason = 'finish_turn',
    bool alreadyEnded = false,
  }) async {
    // barge-in 重开听进行中：勿抢 restore
    if (_turnBusy && endReason != 'wake_fail') {
      AppDebugLog.landscapeVoice(
        'finishTurn skip busy endReason=$endReason',
      );
      return;
    }
    _turnBusy = false;
    _heardEffectiveSpeech = false;
    _disarmBargeIn(reason: 'finish');
    _cancelIdleNoSpeechTimer(reason: 'finish');
    unawaited(_setThinkingWake(false));
    // 兜底：无播音路径也可能残留字幕。
    _clearSubtitle(reason: 'finish_turn');
    final chat = ref.read(voiceChatWsClientProvider);
    if (!alreadyEnded) {
      await chat.endSession(reason: endReason);
    }
    await _restoreWakeListening(
      statusIfOk: kLandscapeWakeHint,
    );
  }

  /// 回唤醒与主壳 resume 共用，避免两路同时开麦。
  Future<void>? _restoreInFlight;
  var _restoreSerial = 0;

  /// 停 chat 麦 → pause 清掉旧订阅 → resume 新建流；失败再 fallback 完整 start。
  Future<void> _restoreWakeListening({required String statusIfOk}) async {
    final ticket = ++_restoreSerial;
    final pending = _restoreInFlight;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
      if (ticket != _restoreSerial) return;
    }
    final run = _restoreWakeListeningBody(statusIfOk: statusIfOk);
    _restoreInFlight = run;
    try {
      await run;
    } finally {
      if (identical(_restoreInFlight, run)) _restoreInFlight = null;
    }
  }

  Future<void> _restoreWakeListeningBody({required String statusIfOk}) async {
    // 仅横屏待唤醒需要 KWS；竖屏 PTT 无 wake。
    if (_surfaceMode != VoiceSurfaceMode.landscape) {
      AppDebugLog.landscapeVoice('restoreWake skip mode=$_surfaceMode');
      return;
    }
    final chat = ref.read(voiceChatWsClientProvider);
    // 等 asr_no_result 里未 await 的停麦收尾完成，避免与 KWS 抢 AudioRecord。
    await chat.ensureMicStopped();
    await Future<void>.delayed(_afterExitResumeGap);
    // 再多让一拍：部分机型 stop→startStream 过快会静音失败。
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!_active) {
      state = state.copyWith(awakened: false, chatListening: false);
      return;
    }
    state = state.copyWith(
      awakened: false,
      statusCaption: statusIfOk,
      chatListening: false,
    );
    _syncChatFlags();

    // 竖屏撕掉过 _wake：补挂而非静默 return。
    if (_wake == null) {
      AppDebugLog.landscapeVoice('restoreWake wakeNull → attach');
      await _attachWakeListening(gen: _lifecycleGen);
      return;
    }
    final wake = _wake!;

    // 订阅还在时 resume 会直接返回，必须先 pause 清掉旧流。
    AppDebugLog.landscapeVoice('restoreWake step=pause');
    await wake.pause();
    AppDebugLog.landscapeVoice('restoreWake step=resume');
    var ok = await wake.resume();
    if (!ok && _active) {
      AppDebugLog.landscapeVoice('restoreWake step=resume_retry');
      await wake.pause();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      ok = await wake.resume();
    }
    if (!ok && _active) {
      AppDebugLog.landscapeVoice('restoreWake step=fallback_start');
      ok = await wake.start(
        onStatus: (s) {
          if (_active) state = state.copyWith(statusCaption: s);
        },
      );
    }
    if (!_active) return;
    _syncChatFlags();
    if (ok) {
      state = state.copyWith(
        listening: true,
        statusCaption: statusIfOk,
      );
      AppDebugLog.landscapeVoice('restoreWake ok');
    } else {
      final reason = wake.unavailableReason ?? '唤醒恢复失败，点按重试';
      AppDebugLog.landscapeVoice('restoreWake fail reason=$reason');
      AppDebugLog.landscapeKws('restoreWake fail reason=$reason');
      state = state.copyWith(
        listening: false,
        statusCaption: reason,
      );
    }
  }

  /// 主壳回到前台：不在聆听、思考或回复播放时重建麦克风流。
  Future<void> rebuildIdleWakeStreamOnResume() async {
    if (!_active || _exitInFlight || _turnBusy) return;
    // 尚未授权：不得偷偷开麦恢复 KWS。
    if (state.micDenied) return;
    if (state.chatListening ||
        _ttsPlaybackActive ||
        _bargeInArmed ||
        state.thinking.isNotEmpty ||
        state.subtitleKind == LandscapeVoiceSubtitleKind.thinking ||
        state.statusCaption.contains('思考中')) {
      return;
    }
    await _restoreWakeListening(statusIfOk: kLandscapeWakeHint);
  }

  /// 点按左下角 / 竖屏球：未激活则补会话；未授权走用途框；假死复位；否则触发唤醒。
  Future<void> onListenChipTap(BuildContext context) async {
    // 冷启竞态兜底：会话未激活时点球再试（dn 已有则 soft activate / 麦权）。
    if (!_active) {
      final dn = _normalizedDeviceNo(ref.read(deviceNoNotifierProvider));
      if (dn == null) {
        state = state.copyWith(
          statusCaption: '绑定宝宝后可语音完成喂养记录',
          micDenied: false,
          chatConnected: false,
          chatListening: false,
        );
        return;
      }
      if (state.micDenied || landscapeMicDeniedThisSession) {
        await _requestMicAndArmWake(context);
        return;
      }
      AppDebugLog.landscapeVoice('chip retry activate (inactive)');
      await activate(ensureMic: softCheckLandscapeMicGranted);
      if (!context.mounted) return;
      if (state.micDenied) {
        await _requestMicAndArmWake(context);
      }
      return;
    }
    if (state.micDenied || landscapeMicDeniedThisSession) {
      await _requestMicAndArmWake(context);
      return;
    }
    // 回复 TTS 播中：不占麦、不停播。
    if (_ttsPlaybackActive) {
      AppDebugLog.landscapeVoice('chip ignore tts_playing');
      return;
    }
    // 已在「请说话/思考中/上行中」：强制 end + 退下，避免假死无响应。
    final forceReset = state.awakened &&
        (state.subtitle.contains('请说话') ||
            state.statusCaption.contains('思考中') ||
            state.chatListening);
    if (forceReset) {
      AppDebugLog.landscapeVoice(
        'chip force reset caption=${state.statusCaption} busy=$_turnBusy',
      );
      _turnBusy = false;
      if (_exitInFlight) return;
      await _exitWithWoXianTuiXia();
      return;
    }
    // 点击开听：与 KWS 分 featureId。
    await _onWakeDetection(fromTap: true);
  }
}

final landscapeVoiceControllerProvider =
    NotifierProvider<LandscapeVoiceController, LandscapeVoiceUiState>(
  LandscapeVoiceController.new,
);

/// 由宿主在「表面可见」时驱动 activate/deactivate。
/// 横屏：预测页可见 + [kPredictionLandscapeVoiceEnabled] → KWS + audio；
/// 竖屏：预测页可见 → FAB PTT 预连（无 KWS，无 portrait 球 flag）；
/// Overlay sheet/dialog 不得单独使竖屏 surface 变 false（见 LandscapeVoiceLifecycleBinder）。
void syncLandscapeVoiceLifecycle(
  WidgetRef ref, {
  required BuildContext context,
  required bool landscape,
  required bool surfaceVisible,
}) {
  final platformOk =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && surfaceVisible;
  final ctrl = ref.read(landscapeVoiceControllerProvider.notifier);
  if (!platformOk) {
    ctrl.setSurfaceWant(false);
    landscapeMicDeniedThisSession = false;
    unawaited(ctrl.deactivate());
    return;
  }
  if (landscape) {
    if (!kPredictionLandscapeVoiceEnabled) {
      ctrl.setSurfaceWant(false);
      landscapeMicDeniedThisSession = false;
      unawaited(ctrl.deactivate());
      return;
    }
    ctrl.setSurfaceWant(true);
    unawaited(ctrl.activate(ensureMic: softCheckLandscapeMicGranted));
    return;
  }
  // 竖屏：预连 chat WS，长按才开麦。
  ctrl.setSurfaceWant(true);
  unawaited(ctrl.activatePortraitPreconnect());
}
