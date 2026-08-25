import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/app_debug_log.dart';
import '../audio/app_voice_record_config.dart';
import '../audio/pcm_level.dart';
import '../config/env.dart';

typedef DeviceNoGetter = String? Function();

/// `/voice/chat/ws` 下行事件（供横屏字幕 / TTS）。
sealed class VoiceChatEvent {
  const VoiceChatEvent();
}

class VoiceChatAsrPartial extends VoiceChatEvent {
  const VoiceChatAsrPartial(this.text);
  final String text;
}

class VoiceChatAsrFinal extends VoiceChatEvent {
  const VoiceChatAsrFinal(this.text);
  final String text;
}

class VoiceChatThinkingDelta extends VoiceChatEvent {
  const VoiceChatThinkingDelta(this.delta);
  final String delta;
}

class VoiceChatAnswer extends VoiceChatEvent {
  const VoiceChatAnswer(this.text);
  final String text;
}

class VoiceChatInterruptCommit extends VoiceChatEvent {
  const VoiceChatInterruptCommit();
}

class VoiceChatTurnEnded extends VoiceChatEvent {
  const VoiceChatTurnEnded({
    required this.ok,
    this.message,
    /// true=结束本段回唤醒；false=服务端要求续聊。缺省 true。
    this.finishTalk = true,
  });
  final bool ok;
  final String? message;
  final bool finishTalk;
}

class VoiceChatExit extends VoiceChatEvent {
  const VoiceChatExit();
}

/// `/voice/chat/ws`：无 JWT；`start`+PCM；解析 thinking/answer/TTS。本期不做 text 上行。
class VoiceChatWsClient {
  VoiceChatWsClient({
    required this.wsUrl,
    required this.deviceNoGetter,
  });

  final String wsUrl;
  final DeviceNoGetter deviceNoGetter;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get readyStream => _readyController.stream;

  final _eventController = StreamController<VoiceChatEvent>.broadcast();
  Stream<VoiceChatEvent> get events => _eventController.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;

  var _handshakeOk = false;
  var _sessionStarted = false;
  var _listening = false;
  Completer<void>? _pongCompleter;
  Completer<void>? _startedCompleter;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSub;
  final _pcmAbsSession = PcmAbsSessionAccumulator();
  var _feedBusy = false;
  Future<bool>? _connectFuture;
  Future<bool>? _restartRoundInFlight;

  /// 成功答完后服务端可能 `waitEndAfterCommit`：下次开听前须 end→start。
  var _needsRoundRestart = false;

  /// 自 `answer` 缓存的 finish_talk；以 `audio_end` 为准覆盖。
  bool? _finishTalkFromAnswer;

  /// 本轮开听是否已出现有效语音能量（见 AppVoiceRecordConfig.effectiveChunkAvgAbs）。
  var _hasEffectiveSpeech = false;
  bool get hasEffectiveSpeech => _hasEffectiveSpeech;

  /// 首次检出有效音时回调（供取消无声 5s）。
  void Function()? onEffectiveSpeech;

  final _ttsPlayer = AudioPlayer();
  final BytesBuilder _ttsPcm = BytesBuilder(copy: false);
  var _ttsSampleRate = AppVoiceRecordConfig.sampleRate;
  var _pcmDiagChunkCount = 0;
  var _ttsPlaying = false;

  /// barge-in 后丢弃迟到 audio_chunk / 抑制 TurnEnded，直至新一轮开听。
  var _ttsDiscard = false;

  bool get isReady => _handshakeOk && _channel != null;
  bool get isListening => _listening;

  void _emitReady(bool v) {
    if (!_readyController.isClosed) _readyController.add(v);
  }

  void _emit(VoiceChatEvent e) {
    if (!_eventController.isClosed) _eventController.add(e);
  }

  Future<bool> connect() async {
    if (AppEnv.disablePangbaoWebSocketSpike) {
      _emitReady(false);
      return false;
    }
    if (wsUrl.isEmpty) {
      _emitReady(false);
      return false;
    }
    final dn = deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _emitReady(false);
      return false;
    }
    if (isReady) return true;
    if (_connectFuture != null) return _connectFuture!;
    _connectFuture = _connectOnce();
    try {
      return await _connectFuture!;
    } finally {
      _connectFuture = null;
    }
  }

  Future<bool> _connectOnce() async {
    await _tearDownSocket(keepPlayer: true);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
      await _channel!.ready.timeout(const Duration(seconds: 8));
      if (!await _waitForPong()) {
        await _tearDownSocket(keepPlayer: true);
        return false;
      }
      _handshakeOk = true;
      _emitReady(true);
      _startPing();
      return true;
    } catch (_) {
      await _tearDownSocket(keepPlayer: true);
      return false;
    }
  }

  Future<bool> _waitForPong() async {
    _pongCompleter = Completer<void>();
    try {
      _channel?.sink.add('ping');
    } catch (_) {
      return false;
    }
    try {
      await _pongCompleter!.future.timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    } finally {
      _pongCompleter = null;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!isReady) return;
      try {
        _channel?.sink.add('ping');
      } catch (_) {
        _handleDisconnect();
      }
    });
  }

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;
    if (raw == 'pong') {
      if (!(_pongCompleter?.isCompleted ?? true)) {
        _pongCompleter!.complete();
      }
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _dispatchJson(map);
    } catch (_) {}
  }

  /// 解析服务端 finish_talk；无法解析返回 null。
  static bool? _parseFinishTalk(Map<String, dynamic> map) {
    final v = map['finish_talk'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return null;
  }

  void _dispatchJson(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'started':
        _sessionStarted = true;
        if (!(_startedCompleter?.isCompleted ?? true)) {
          _startedCompleter!.complete();
        }
      case 'asr_partial':
        final text = (map['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) _emit(VoiceChatAsrPartial(text));
      case 'asr_final':
        final text = (map['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) _emit(VoiceChatAsrFinal(text));
      case 'asr_no_result':
        // 空片段：编排层 soft rearm；不在此发 end。
        unawaited(_stopMicOnly());
        _emit(const VoiceChatTurnEnded(ok: false, message: 'asr_no_result'));
      case 'thinking_delta':
        final delta = (map['delta'] as String?) ??
            (map['text'] as String?) ??
            '';
        if (delta.isNotEmpty) _emit(VoiceChatThinkingDelta(delta));
      case 'answer':
        // 预缓存 finish_talk；话轮结束以 audio_end 为准。
        final fromAnswer = _parseFinishTalk(map);
        if (fromAnswer != null) {
          _finishTalkFromAnswer = fromAnswer;
          AppDebugLog.landscapeVoice(
            'finish_talk from answer=$fromAnswer',
          );
        }
        final text = (map['text'] as String?) ??
            (map['answer'] as String?) ??
            '';
        if (text.isNotEmpty) _emit(VoiceChatAnswer(text));
      case 'audio_chunk':
        unawaited(_onAudioChunk(map));
      case 'audio_end':
        unawaited(_onAudioEnd(map));
      case 'interrupt_commit':
        _emit(const VoiceChatInterruptCommit());
        unawaited(_stopMicOnly());
      case 'exit':
        // 停麦 + end 再通知编排层回唤醒。
        unawaited(_onServerExit());
      case 'error':
        final msg = map['message'] as String? ?? 'voice chat error';
        if (!(_startedCompleter?.isCompleted ?? true)) {
          _startedCompleter!.completeError(msg);
        }
        _emit(VoiceChatTurnEnded(ok: false, message: msg));
      case 'ended':
        _sessionStarted = false;
        _needsRoundRestart = false;
      default:
        // 未知 type：忽略不断连（对齐硬件客户端）
        break;
    }
  }

  Future<void> _onServerExit() async {
    await _stopMicOnly();
    await endSession(reason: 'server_exit');
    _emit(const VoiceChatExit());
  }

  Future<void> _onAudioChunk(Map<String, dynamic> map) async {
    // barge-in 停播后忽略迟到分片
    if (_ttsDiscard) return;
    final b64 = map['audio'] as String?;
    if (b64 == null || b64.isEmpty) return;
    try {
      _ttsPcm.add(base64Decode(b64));
    } catch (_) {
      return;
    }
    final sr = map['sampleRate'];
    if (sr is int && sr > 0) _ttsSampleRate = sr;
  }

  Future<void> _onAudioEnd(Map<String, dynamic> map) async {
    // audio_end 优先；否则用 answer 缓存；再缺省结束本段。
    final fromEnd = _parseFinishTalk(map);
    final finishTalk = fromEnd ?? _finishTalkFromAnswer ?? true;
    final src = fromEnd != null
        ? 'audio_end'
        : (_finishTalkFromAnswer != null ? 'answer_cache' : 'default_true');
    AppDebugLog.landscapeVoice('finish_talk=$finishTalk src=$src');
    _finishTalkFromAnswer = null;

    if (_ttsDiscard) {
      // 唤醒打断已接管生命周期，勿再发 TurnEnded
      _ttsPcm.clear();
      AppDebugLog.landscapeVoice('audio_end skipped ttsDiscard');
      return;
    }

    // 成功答完后服务端武装 waitEndAfterCommit。
    _needsRoundRestart = true;

    final bytes = _ttsPcm.takeBytes();
    _ttsPcm.clear();
    if (bytes.isEmpty) {
      _emit(VoiceChatTurnEnded(ok: true, finishTalk: finishTalk));
      return;
    }
    try {
      await _playPcm16Le(bytes, _ttsSampleRate);
      if (_ttsDiscard) {
        AppDebugLog.landscapeVoice('tts play aborted discard');
        return;
      }
      _emit(VoiceChatTurnEnded(ok: true, finishTalk: finishTalk));
    } catch (e) {
      if (_ttsDiscard) {
        AppDebugLog.landscapeVoice('tts play err discarded e=$e');
        return;
      }
      _emit(VoiceChatTurnEnded(ok: false, message: '$e', finishTalk: finishTalk));
    }
  }

  /// 唤醒打断：立即停 TTS、清缓冲，并丢弃本轮后续音频直至新开听。
  Future<void> stopTts() async {
    _ttsDiscard = true;
    _ttsPcm.clear();
    if (_ttsPlaying) {
      try {
        await _ttsPlayer.stop();
      } catch (_) {}
      _ttsPlaying = false;
    }
    AppDebugLog.landscapeVoice('stopTts');
  }

  Future<void> _playPcm16Le(Uint8List pcm, int sampleRate) async {
    if (_ttsPlaying) {
      try {
        await _ttsPlayer.stop();
      } catch (_) {}
    }
    _ttsPlaying = true;
    try {
      final wav = _pcm16ToWav(pcm, sampleRate: sampleRate);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}voice_chat_tts_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await file.writeAsBytes(wav, flush: true);
      await _ttsPlayer.play(DeviceFileSource(file.path));
      try {
        await _ttsPlayer.onPlayerComplete.first.timeout(
          const Duration(minutes: 2),
        );
      } on TimeoutException {
        AppDebugLog.landscapeVoice('tts play timeout');
      }
      try {
        await file.delete();
      } catch (_) {}
    } finally {
      _ttsPlaying = false;
    }
  }

  /// 本地短 wav（「我在」/「我先退下了」等）。
  Future<void> playAssetWav(String assetPath) async {
    try {
      if (_ttsPlaying) {
        try {
          await _ttsPlayer.stop();
        } catch (_) {}
      }
      _ttsPlaying = true;
      // mediaPlayer 更易完整播完短提示音；低延迟模式易片头裁切。
      await _ttsPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _ttsPlayer.setReleaseMode(ReleaseMode.stop);
      await _ttsPlayer.play(AssetSource(assetPath));
      try {
        await _ttsPlayer.onPlayerComplete.first.timeout(
          const Duration(seconds: 12),
        );
      } on TimeoutException {
        AppDebugLog.landscapeVoice('playAssetWav timeout path=$assetPath');
      }
    } catch (e) {
      AppDebugLog.landscapeVoice('playAssetWav err=$e path=$assetPath');
    } finally {
      _ttsPlaying = false;
    }
  }

  static Uint8List _pcm16ToWav(Uint8List pcm, {required int sampleRate}) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.length;
    final buffer = BytesBuilder(copy: false);
    void writeStr(String s) => buffer.add(ascii.encode(s));
    void write32(int v) {
      final b = ByteData(4)..setUint32(0, v, Endian.little);
      buffer.add(b.buffer.asUint8List());
    }

    void write16(int v) {
      final b = ByteData(2)..setUint16(0, v, Endian.little);
      buffer.add(b.buffer.asUint8List());
    }

    writeStr('RIFF');
    write32(36 + dataSize);
    writeStr('WAVE');
    writeStr('fmt ');
    write32(16);
    write16(1);
    write16(channels);
    write32(sampleRate);
    write32(byteRate);
    write16(blockAlign);
    write16(bitsPerSample);
    writeStr('data');
    write32(dataSize);
    buffer.add(pcm);
    return buffer.takeBytes();
  }

  void _handleDisconnect() {
    unawaited(_tearDownSocket(keepPlayer: true));
  }

  Future<void> _tearDownSocket({required bool keepPlayer}) async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _stopMicOnly();
    _handshakeOk = false;
    _sessionStarted = false;
    _needsRoundRestart = false;
    _finishTalkFromAnswer = null;
    final pong = _pongCompleter;
    if (pong != null && !pong.isCompleted) {
      pong.completeError(StateError('disconnected'));
    }
    _pongCompleter = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _emitReady(false);
    if (!keepPlayer) {
      try {
        await _ttsPlayer.dispose();
      } catch (_) {}
    }
  }

  Future<void> disconnect() => _tearDownSocket(keepPlayer: true);

  /// 确保已 `start` 流式会话（可跨多轮复用连接）。
  Future<bool> ensureSessionStarted() async {
    if (!await connect()) {
      AppDebugLog.landscapeVoice('ensureSession connect fail');
      return false;
    }
    if (_sessionStarted) return true;
    final dn = deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      AppDebugLog.landscapeVoice('ensureSession no deviceNo');
      return false;
    }
    _startedCompleter = Completer<void>();
    final start = jsonEncode({
      'type': 'start',
      'deviceNo': dn,
      'sampleRate': AppVoiceRecordConfig.sampleRate,
      'bits': 16,
      'channels': 1,
      'length': 32000,
      'mode': 'stream',
    });
    try {
      AppDebugLog.landscapeVoice('ensureSession send start');
      _channel!.sink.add(start);
      await _startedCompleter!.future.timeout(const Duration(seconds: 8));
      AppDebugLog.landscapeVoice('ensureSession started=$_sessionStarted');
      return _sessionStarted;
    } catch (e) {
      AppDebugLog.landscapeVoice('ensureSession err=$e');
      return false;
    }
  }

  /// 清 waitEndAfterCommit：`end` 再 `start`（single-flight）。
  Future<bool> restartAudioRound() async {
    if (_restartRoundInFlight != null) return _restartRoundInFlight!;
    _restartRoundInFlight = _restartAudioRoundOnce();
    try {
      return await _restartRoundInFlight!;
    } finally {
      _restartRoundInFlight = null;
    }
  }

  Future<bool> _restartAudioRoundOnce() async {
    await _stopMicOnly();
    AppDebugLog.landscapeVoice(
      'restartRound end then start sessionWas=$_sessionStarted',
    );
    if (isReady) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'end'}));
      } catch (e) {
        AppDebugLog.landscapeVoice('restartRound end err=$e');
      }
    }
    _sessionStarted = false;
    _needsRoundRestart = false;
    return ensureSessionStarted();
  }

  /// 唤醒后开始上送用户 PCM（双端共用）。
  ///
  /// [resetEffectiveSpeech] 为 false 时保留本轮「已有有效音」标记（空片段续听）。
  Future<bool> beginListen({bool resetEffectiveSpeech = true}) async {
    // 答完后须 end→start，禁止仅凭 _sessionStarted 继续喂 PCM。
    if (_needsRoundRestart) {
      if (!await restartAudioRound()) return false;
    } else if (!await ensureSessionStarted()) {
      return false;
    }
    if (_listening) return true;
    // 权限须在横屏用途框流程中已授予；此处不再静默弹系统框。
    if (!await _recorder.hasPermission(request: false)) {
      AppDebugLog.landscapeVoice('beginListen no mic permission');
      return false;
    }
    await _stopMicOnly();
    _ttsPcm.clear();
    // 新一轮上行：允许再收 TTS
    _ttsDiscard = false;
    _pcmAbsSession.reset();
    _pcmDiagChunkCount = 0;
    if (resetEffectiveSpeech) {
      _hasEffectiveSpeech = false;
    }
    try {
      AppDebugLog.landscapeVoice('beginListen startStream');
      final stream = await _recorder
          .startStream(AppVoiceRecordConfig.pcm16kMono)
          .timeout(const Duration(seconds: 5));
      _listening = true;
      _pcmSub = stream.listen((bytes) {
        unawaited(_sendPcm(bytes));
      });
      AppDebugLog.landscapeVoice('beginListen ok');
      return true;
    } catch (e) {
      AppDebugLog.landscapeVoice('beginListen err=$e');
      _listening = false;
      try {
        if (await _recorder.isRecording()) await _recorder.stop();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _sendPcm(Uint8List bytes) async {
    if (!_listening || !isReady || bytes.isEmpty || _feedBusy) return;
    _feedBusy = true;
    try {
      // 会话级 avgAbs 累计；并检测本轮有效音。
      final metrics = pcm16ProcessChunk(bytes, _pcmAbsSession);
      _pcmDiagChunkCount++;
      if (kDebugMode &&
          (_pcmDiagChunkCount % 25 == 0 ||
              metrics.chunkAvgAbs >=
                  AppVoiceRecordConfig.effectiveChunkAvgAbs)) {
        AppDebugLog.landscapeVoice(
          'pcm chunkAvgAbs=${metrics.chunkAvgAbs} sessionAvgAbs=${metrics.sessionAvgAbs}',
        );
      }
      if (!_hasEffectiveSpeech &&
          metrics.chunkAvgAbs >= AppVoiceRecordConfig.effectiveChunkAvgAbs) {
        _hasEffectiveSpeech = true;
        AppDebugLog.landscapeVoice(
          'effectiveSpeech avgAbs=${metrics.chunkAvgAbs}',
        );
        onEffectiveSpeech?.call();
      }
      _channel?.sink.add(bytes);
    } catch (_) {
      _handleDisconnect();
    } finally {
      _feedBusy = false;
    }
  }

  Future<void> _stopMicOnly() async {
    _listening = false;
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// 轮次结束、交还 KWS 前：等待用户上行麦彻底释放。
  Future<void> ensureMicStopped() => _stopMicOnly();

  /// 客户端主动 commit（服务端亦可 interrupt_commit）。
  Future<void> commitUtterance() async {
    await _stopMicOnly();
    try {
      _channel?.sink.add(jsonEncode({'type': 'commit'}));
    } catch (_) {}
  }

  /// 客户端主动结束音频会话窗（idle / 回唤醒 / dispose）。
  Future<void> endSession({String reason = 'end'}) async {
    await _stopMicOnly();
    final shouldSend = isReady;
    if (shouldSend) {
      try {
        AppDebugLog.landscapeVoice('endSession reason=$reason');
        _channel?.sink.add(jsonEncode({'type': 'end'}));
      } catch (e) {
        AppDebugLog.landscapeVoice('endSession err=$e reason=$reason');
      }
    } else {
      AppDebugLog.landscapeVoice('endSession skip_send reason=$reason');
    }
    _sessionStarted = false;
    _needsRoundRestart = false;
    _finishTalkFromAnswer = null;
    // end 后若未立刻开听，保持 discard 直至 beginListen 清除
  }

  Future<void> dispose() async {
    await endSession(reason: 'dispose');
    await _tearDownSocket(keepPlayer: false);
    await _recorder.dispose();
    await _readyController.close();
    await _eventController.close();
  }
}
