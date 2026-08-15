import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../util/thinking_stage_delta.dart';
import '../voice/landscape_mic_permission.dart';
import '../voice/landscape_wake_word.dart';
import '../voice/voice_chat_ws_client.dart';
import 'device_no_notifier.dart';
import 'voice_chat_ws_provider.dart';

/// 本地「我在」提示音。
const kLandscapeWoZaiAsset = 'audio/wo_zai.wav';

/// 本地「我先退下了」提示音（对齐硬件 exit_dialog）。
const kLandscapeExitDialogAsset = 'audio/wo_xian_tui_xia_le.wav';

/// 横屏弹幕角色：思考态浅字+脉冲，其余满对比。
enum LandscapeVoiceSubtitleKind {
  none,
  asr,
  thinking,
  answer,
}

/// 横屏语音会话 UI 状态。
@immutable
class LandscapeVoiceUiState {
  const LandscapeVoiceUiState({
    this.listening = false,
    this.awakened = false,
    this.subtitle = '',
    this.subtitleKind = LandscapeVoiceSubtitleKind.none,
    this.statusCaption = '说「你好，胖宝」唤醒我',
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

  /// 思考/TTS 阶段已 resume KWS，可唤醒打断。
  var _bargeInArmed = false;

  /// 本轮开听是否已出现有效音（跨 soft rearm 保留）。
  var _heardEffectiveSpeech = false;

  Timer? _idleNoSpeechTimer;

  static const _micHandoffTimeout = Duration(seconds: 5);
  static const _micHandoffGap = Duration(milliseconds: 400);
  static const _afterPromptGap = Duration(milliseconds: 400);
  static const _afterExitResumeGap = Duration(milliseconds: 350);
  static const _idleNoSpeech = Duration(seconds: 5);

  @override
  LandscapeVoiceUiState build() {
    ref.onDispose(() {
      _cancelIdleNoSpeechTimer(reason: 'dispose');
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

  /// 更新字幕并标注角色（思考态供弹幕浅字+脉冲）。
  void _setSubtitle(
    String text, {
    required LandscapeVoiceSubtitleKind kind,
  }) {
    state = state.copyWith(subtitle: text, subtitleKind: kind);
  }

  /// 播完音频或本轮结束时清空弹幕。
  void _clearSubtitle({required String reason}) {
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

  void _cancelIdleNoSpeechTimer({required String reason}) {
    if (_idleNoSpeechTimer != null) {
      AppDebugLog.landscapeVoice('idle cancel reason=$reason');
    }
    _idleNoSpeechTimer?.cancel();
    _idleNoSpeechTimer = null;
  }

  /// 开听成功后武装 5s 无声退出。
  void _armIdleNoSpeechTimer() {
    _cancelIdleNoSpeechTimer(reason: 'rearm');
    AppDebugLog.landscapeVoice('idle arm ${_idleNoSpeech.inSeconds}s');
    _idleNoSpeechTimer = Timer(_idleNoSpeech, () {
      if (!_active || _exitInFlight) return;
      final chat = ref.read(voiceChatWsClientProvider);
      if (_heardEffectiveSpeech || chat.hasEffectiveSpeech) {
        AppDebugLog.landscapeVoice('idle fire skipped hasSpeech');
        return;
      }
      AppDebugLog.landscapeVoice('idle fire');
      unawaited(_exitWithWoXianTuiXia());
    });
  }

  void _onEffectiveSpeechDetected() {
    if (_heardEffectiveSpeech) return;
    _heardEffectiveSpeech = true;
    _cancelIdleNoSpeechTimer(reason: 'effective');
  }

  /// 预测页横屏可见时调用；[ensureMic] 负责用途框 + 系统权限。
  Future<void> activate({
    required Future<bool> Function() ensureMic,
  }) async {
    if (kIsWeb) return;
    if (_active) return;

    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) {
      state = state.copyWith(
        statusCaption: '绑定宝宝后可语音对话',
        micDenied: false,
        chatConnected: false,
        chatListening: false,
      );
      return;
    }

    final micOk = await ensureMic();
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
    if (!_active) return;
    _syncChatFlags();
    state = state.copyWith(
      listening: wakeOk,
      statusCaption: wakeOk
          ? '说「你好，胖宝」唤醒我'
          : (_wake!.unavailableReason ?? '唤醒未就绪'),
    );
  }

  Future<void> deactivate() async {
    _active = false;
    _cancelIdleNoSpeechTimer(reason: 'deactivate');
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
    await chat.endSession(reason: 'teardown');
    await chat.disconnect();
    _turnBusy = false;
    _exitInFlight = false;
    _heardEffectiveSpeech = false;
    _bargeInArmed = false;
  }

  void _disarmBargeIn({required String reason}) {
    if (!_bargeInArmed) return;
    _bargeInArmed = false;
    AppDebugLog.landscapeVoice('bargeIn disarm reason=$reason');
  }

  /// 思考/TTS 窗口：停上行麦后 resume KWS，供再说唤醒词打断。
  Future<void> _armBargeInWake() async {
    if (!_active || _exitInFlight) return;
    final chat = ref.read(voiceChatWsClientProvider);
    if (chat.isListening) return;
    if (!state.awakened) return;

    await chat.ensureMicStopped();
    await Future<void>.delayed(_afterExitResumeGap);
    if (!_active || _exitInFlight || chat.isListening || !state.awakened) {
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
    if (!_active || !_bargeInArmed) return;
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

  /// 检测分流：对话段内 barge-in vs 待唤醒普通唤醒。
  Future<void> _onWakeDetection() async {
    if (!_active) return;
    if (_bargeInArmed && state.awakened) {
      await _onBargeInWake();
      return;
    }
    await _onWake();
  }

  /// 思考/TTS 中再说唤醒词：停 TTS → end →「我在」→ 开听。
  Future<void> _onBargeInWake() async {
    if (!_active || _turnBusy) return;
    _turnBusy = true;
    _disarmBargeIn(reason: 'hit');
    _exitInFlight = false;
    _heardEffectiveSpeech = false;
    _cancelIdleNoSpeechTimer(reason: 'barge_in');
    AppDebugLog.landscapeVoice('bargeIn hit');

    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    try {
      await chat.stopTts();
      await chat.endSession(reason: 'wake_barge_in');
      _setSubtitle('我在', kind: LandscapeVoiceSubtitleKind.asr);
      state = state.copyWith(
        awakened: true,
        thinking: '',
        statusCaption: '我在听…',
        chatListening: false,
      );

      state = state.copyWith(statusCaption: '正在让出麦克风…');
      AppDebugLog.landscapeVoice('bargeIn step=pause');
      await _wake?.pause().timeout(_micHandoffTimeout);
      await Future<void>.delayed(_micHandoffGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      state = state.copyWith(statusCaption: '我在听…');
      AppDebugLog.landscapeVoice('bargeIn step=play_wo_zai');
      await chat.playAssetWav(kLandscapeWoZaiAsset);
      _clearSubtitle(reason: 'wo_zai_done');
      await Future<void>.delayed(_afterPromptGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      state = state.copyWith(statusCaption: '正在接通会话…');
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
      state = state.copyWith(
        statusCaption: '请说话…',
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
    _setSubtitle('我在', kind: LandscapeVoiceSubtitleKind.asr);
    state = state.copyWith(
      awakened: true,
      thinking: '',
      statusCaption: '我在听…',
    );
    final chat = ref.read(voiceChatWsClientProvider);
    chat.onEffectiveSpeech = _onEffectiveSpeechDetected;
    try {
      state = state.copyWith(statusCaption: '正在让出麦克风…');
      AppDebugLog.landscapeVoice('wake step=pause');
      await _wake?.pause().timeout(_micHandoffTimeout);
      await Future<void>.delayed(_micHandoffGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      state = state.copyWith(statusCaption: '我在听…');
      AppDebugLog.landscapeVoice('wake step=play_wo_zai');
      await chat.playAssetWav(kLandscapeWoZaiAsset);
      _clearSubtitle(reason: 'wo_zai_done');
      await Future<void>.delayed(_afterPromptGap);

      if (!_active) {
        _turnBusy = false;
        return;
      }
      state = state.copyWith(statusCaption: '正在接通会话…');
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
      state = state.copyWith(
        statusCaption: '请说话…',
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
    state = state.copyWith(
      thinking: '',
      statusCaption: '请说话…',
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
    state = state.copyWith(
      statusCaption: '请说话…',
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
        state = state.copyWith(
          statusCaption: '请说话…',
          chatListening: true,
          awakened: true,
        );
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
      state = state.copyWith(
        statusCaption: '请说话…',
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
    state = state.copyWith(
      statusCaption: _heardEffectiveSpeech ? '思考中…' : '请说话…',
      chatListening: false,
    );
    _syncChatFlags();
    // 仅有效音后的思考/TTS 窗口武装 barge-in（空结果续听不开）
    if (_heardEffectiveSpeech) {
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
    // 兜底：无播音路径也可能残留字幕。
    _clearSubtitle(reason: 'finish_turn');
    final chat = ref.read(voiceChatWsClientProvider);
    if (!alreadyEnded) {
      await chat.endSession(reason: endReason);
    }
    await _restoreWakeListening(
      statusIfOk: '说「你好，胖宝」唤醒我',
    );
  }

  /// 停 chat 麦 → 短延迟 → resume；失败重试再 fallback 完整 start。
  Future<void> _restoreWakeListening({required String statusIfOk}) async {
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

    AppDebugLog.landscapeVoice('restoreWake step=resume');
    var ok = await wake.resume();
    if (!ok && _active) {
      AppDebugLog.landscapeVoice('restoreWake step=resume_retry');
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

  /// 点按左下角：权限被拒时重试用途框；「请说话」假死可强制复位；否则触发唤醒。
  Future<void> onListenChipTap(BuildContext context) async {
    if (state.micDenied || landscapeMicDeniedThisSession) {
      landscapeMicDeniedThisSession = false;
      await activate(ensureMic: () => ensureLandscapeMicPermission(context));
      return;
    }
    // 已在「请说话/思考中/上行中」：强制 end + 退下，避免假死无响应。
    final forceReset = state.awakened &&
        (state.statusCaption.contains('请说话') ||
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
    await _onWakeDetection();
  }
}

final landscapeVoiceControllerProvider =
    NotifierProvider<LandscapeVoiceController, LandscapeVoiceUiState>(
  LandscapeVoiceController.new,
);

/// 由预测页在横屏∩可见时驱动 activate/deactivate。
void syncLandscapeVoiceLifecycle(
  WidgetRef ref, {
  required BuildContext context,
  required bool landscape,
  required bool predictionVisible,
}) {
  final want = !kIsWeb &&
      landscape &&
      predictionVisible &&
      (Platform.isAndroid || Platform.isIOS);
  final ctrl = ref.read(landscapeVoiceControllerProvider.notifier);
  if (want) {
    unawaited(
      ctrl.activate(
        ensureMic: () => ensureLandscapeMicPermission(context),
      ),
    );
  } else {
    // 离开横屏：清会话拒绝标记，下次进入可再提示用途。
    landscapeMicDeniedThisSession = false;
    unawaited(ctrl.deactivate());
  }
}
