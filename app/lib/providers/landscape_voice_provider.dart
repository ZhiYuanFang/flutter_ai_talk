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
    return const LandscapeVoiceUiState();
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

  /// 预测页横屏可见时调用；[ensureMic] 负责用途框 + 系统权限。
  Future<void> activate({
    required Future<bool> Function() ensureMic,
  }) async {
    if (kIsWeb) return;
    if (_active) return;
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

    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) {
      state = state.copyWith(
        statusCaption: '绑定宝宝后可语音完成喂养记录',
        micDenied: false,
        chatConnected: false,
        chatListening: false,
      );
      return;
    }

    final micOk = await ensureMic();
    if (gen != _lifecycleGen) return;
    if (!micOk) {
      state = state.copyWith(
        listening: false,
        micDenied: true,
        statusCaption: '需要麦克风权限才能语音唤醒（点按重试）',
        chatConnected: false,
        chatListening: false,
      );
      return;
    }

    _active = true;
    state = state.copyWith(micDenied: false);

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
      if (!ok) {
        state = state.copyWith(statusCaption: '语音通道连接中…可稍后再试');
      }
    }));

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
      statusCaption: wakeOk
          ? kLandscapeWakeHint
          : (_wake!.unavailableReason ?? '唤醒未就绪'),
    );
  }

  Future<void> deactivate() async {
    _lifecycleGen++;
    _active = false;
    _cancelIdleNoSpeechTimer(reason: 'deactivate');
    final inflight = _activateInFlight;
    if (inflight != null) {
      try {
        await inflight;
      } catch (_) {}
    }
    await _tearDown();
    state = const LandscapeVoiceUiState();
  }

  Future<void> _tearDown() async {
    _cancelIdleNoSpeechTimer(reason: 'teardown');
    await _wakeSub?.cancel();
    _wakeSub = null;
    await _wake?.stop();
    await _chatSub?.cancel();
    _chatSub = null;
    await _readySub?.cancel();
    _readySub = null;
    final chat = ref.read(voiceChatWsClientProvider);
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
      AppDebugLog.landscapeVoice('bargeIn step=beginListen');
      final ok = await chat.beginListen().timeout(_micHandoffTimeout);
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
      AppDebugLog.landscapeVoice('wake step=beginListen');
      final ok = await chat.beginListen().timeout(_micHandoffTimeout);
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
        state = state.copyWith(chatListening: false);
        unawaited(_afterServerCommit());
      case VoiceChatTurnEnded(:final ok, :final message, :final finishTalk):
        _ttsPlaybackActive = false;
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
    final ok = await chat.beginListen(resetEffectiveSpeech: true);
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
      final ok = await chat.beginListen(resetEffectiveSpeech: false);
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
    final ok = await chat.beginListen(resetEffectiveSpeech: false);
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
    final chat = ref.read(voiceChatWsClientProvider);
    // 等 asr_no_result 里未 await 的停麦收尾完成。
    await chat.ensureMicStopped();
    await Future<void>.delayed(_afterExitResumeGap);
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

    final wake = _wake;
    if (wake == null) return;

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
      state = state.copyWith(
        listening: false,
        statusCaption: reason,
      );
    }
  }

  /// 主壳回到前台：不在聆听、思考或回复播放时重建麦克风流。
  Future<void> rebuildIdleWakeStreamOnResume() async {
    if (!_active || _exitInFlight || _turnBusy) return;
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

  /// 点按左下角：权限被拒时重试用途框；「请说话」假死可强制复位；否则触发唤醒。
  Future<void> onListenChipTap(BuildContext context) async {
    if (state.micDenied || landscapeMicDeniedThisSession) {
      landscapeMicDeniedThisSession = false;
      await activate(ensureMic: () => ensureLandscapeMicPermission(context));
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

/// 由宿主在「表面可见 ∩ 对应方向 flag 开启」时驱动 activate/deactivate。
/// 横屏：预测页可见 + [kPredictionLandscapeVoiceEnabled]；
/// 竖屏：主壳表面（未被其它 PageRoute 覆盖、非 UCG 未合格等）+ [kPredictionPortraitVoiceEnabled]；
/// Overlay sheet/dialog 不得单独使竖屏 surface 变 false（见 LandscapeVoiceLifecycleBinder）。
void syncLandscapeVoiceLifecycle(
  WidgetRef ref, {
  required BuildContext context,
  required bool landscape,
  required bool surfaceVisible,
}) {
  // 竖/横各自独立 flag；平台仍限非 Web 的 Android/iOS
  final orientationOk = landscape
      ? kPredictionLandscapeVoiceEnabled
      : kPredictionPortraitVoiceEnabled;
  final want = !kIsWeb &&
      surfaceVisible &&
      orientationOk &&
      (Platform.isAndroid || Platform.isIOS);
  final ctrl = ref.read(landscapeVoiceControllerProvider.notifier);
  if (want) {
    unawaited(
      ctrl.activate(
        ensureMic: () => ensureLandscapeMicPermission(context),
      ),
    );
  } else {
    // 离开应激活的预测语音表面：清会话拒绝标记，下次进入可再提示用途。
    landscapeMicDeniedThisSession = false;
    unawaited(ctrl.deactivate());
  }
}
