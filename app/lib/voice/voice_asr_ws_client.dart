import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../audio/app_voice_record_config.dart';
import '../audio/pcm_level.dart';
import '../config/env.dart';

typedef DeviceNoGetter = String? Function();

/// `/voice/asr/ws`：仅实时转写，无鉴权；`start` 携带 [deviceNo]。
///
/// 服务端应对 `asr_partial` / `asr_final` 的 `text` 下发「本次 start…commit 会话全文」。
/// 整轮业务定稿仍仅在 client `commit` 之后的 `asr_final`；引擎句末不会单独结束 utterance。
class VoiceAsrWsClient {
  VoiceAsrWsClient({
    required this.wsUrl,
    required this.deviceNoGetter,
  });

  final String wsUrl;
  final DeviceNoGetter deviceNoGetter;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get readyStream => _readyController.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;

  /// 仅当 WebSocket 握手成功且收到服务端 `pong` 后为 true（非「调用了 connect」）。
  var _handshakeOk = false;
  var _utteranceActive = false;
  Completer<void>? _pongCompleter;

  void Function(String partial)? _onPartial;
  void Function(double level)? _onLevel;
  void Function({required int chunkAvgAbs, required int sessionAvgAbs})?
      _onPcmDiagnostics;
  final _pcmAbsSession = PcmAbsSessionAccumulator();

  /// 整轮收束 Completer：仅在 [commitSent] 后由 final / no_result / timeout 完成。
  Completer<String>? _utteranceDone;
  Completer<void>? _startedCompleter;

  /// 当前会话草稿全文（以下行 text 为准，旧服务端段重置时本地兜底拼接）
  var _sessionDraft = '';
  /// 是否已发送 commit（之后的 final 才结束整轮）
  var _commitSent = false;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSub;
  var _feedBusy = false;
  Future<bool>? _connectFuture;

  bool get isReady => _handshakeOk && _channel != null;

  void _emitReady(bool v) {
    if (!_readyController.isClosed) {
      _readyController.add(v);
    }
  }

  /// 段拼接：单段 trim 后直接相连（中文听写）
  static String joinSegments(String a, String b) {
    final left = a.trim();
    final right = b.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    return '$left$right';
  }

  /// 在 fromEngine 与本地草稿间取更完整者（防短 final 覆盖长预览）
  static String preferRicherTranscript(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.isEmpty) return y;
    if (y.isEmpty) return x;
    if (x.contains(y) || x.startsWith(y)) return x;
    if (y.contains(x) || y.startsWith(x)) return y;
    return x.length >= y.length ? x : y;
  }

  void _resetUtteranceAccum() {
    _sessionDraft = '';
    _commitSent = false;
  }

  /// 采纳服务端下行 text：优先当会话全文；仅旧服「短末句重置」才本地拼段（防 AA）
  void _applyServerDraft(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    final prev = _sessionDraft.trim();
    if (prev.isEmpty) {
      _sessionDraft = t;
    } else if (t == prev) {
      return;
    } else if (t.startsWith(prev) || prev.startsWith(t)) {
      // 同句伸长/缩短或服务端全文伸长
      _sessionDraft = preferRicherTranscript(prev, t);
    } else if (t.contains(prev)) {
      // 下行已包含旧草稿 → 服务端全文，直接采用（勿再 join）
      _sessionDraft = t;
    } else if (prev.contains(t)) {
      // 新帧是旧草稿子集（重复末句 / 回退）→ 保持 prev，避免拼成 AA
      return;
    } else if (t.length < prev.length) {
      // 旧服段重置：较短新句且无包含关系 → 拼段
      _sessionDraft = joinSegments(prev, t);
    } else {
      // 更长且无关：采更长者，避免误 join 造成重复
      _sessionDraft = preferRicherTranscript(prev, t);
    }
    _onPartial?.call(_sessionDraft);
  }

  void _completeUtteranceDone(String text) {
    if (!(_utteranceDone?.isCompleted ?? true)) {
      _utteranceDone!.complete(text);
    }
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
    await _tearDownSocket();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: true,
      );
      await _channel!.ready.timeout(const Duration(seconds: 8));
      final pongOk = await _waitForPong();
      if (!pongOk) {
        await _tearDownSocket();
        return false;
      }
      _handshakeOk = true;
      _emitReady(true);
      _startPing();
      return true;
    } catch (_) {
      await _tearDownSocket();
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
    } on TimeoutException {
      return false;
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

  void _dispatchJson(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'started':
        if (!(_startedCompleter?.isCompleted ?? true)) {
          _startedCompleter!.complete();
        }
      case 'asr_partial':
        final text = map['text'] as String? ?? '';
        if (text.isNotEmpty) {
          _applyServerDraft(text);
        }
      case 'asr_final':
        final text = map['text'] as String? ?? '';
        if (text.isNotEmpty) {
          // 定稿全文：与草稿取更完整者
          _sessionDraft = preferRicherTranscript(_sessionDraft, text);
          _onPartial?.call(_sessionDraft);
        }
        if (_commitSent) {
          _completeUtteranceDone(_sessionDraft);
        }
      case 'asr_no_result':
        if (_commitSent) {
          _completeUtteranceDone(_sessionDraft);
        }
      case 'ended':
        break;
      case 'error':
        if (!(_startedCompleter?.isCompleted ?? true)) {
          _startedCompleter!.completeError(
            map['message'] as String? ?? 'voice asr error',
          );
        }
        if (_commitSent) {
          _completeUtteranceDone(_sessionDraft);
        }
    }
  }

  void _handleDisconnect() {
    unawaited(_tearDownSocket());
  }

  Future<void> _tearDownSocket() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _stopPcm();
    _utteranceActive = false;
    _handshakeOk = false;
    final pending = _sessionDraft;
    _completeUtteranceDone(pending);
    _resetUtteranceAccum();
    _onPartial = null;
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
  }

  /// 登出或离开 Home：断开 ASR WebSocket，保留 client 供下次 connect。
  Future<void> disconnect() => _tearDownSocket();

  Future<void> _stopPcm() async {
    _onLevel = null;
    _onPcmDiagnostics = null;
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<bool> beginUtterance(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    void Function({required int chunkAvgAbs, required int sessionAvgAbs})?
        onPcmDiagnostics,
  }) async {
    if (!await connect()) return false;

    final dn = deviceNoGetter();
    if (dn == null || dn.isEmpty) return false;

    await _stopPcm();
    _pcmAbsSession.reset();
    _resetUtteranceAccum();
    _onPartial = onPartial;
    _onLevel = onLevel;
    _onPcmDiagnostics = onPcmDiagnostics;
    _utteranceDone = Completer<String>();
    _startedCompleter = Completer<void>();
    _utteranceActive = true;

    final start = jsonEncode({
      'type': 'start',
      'deviceNo': dn,
      'sampleRate': AppVoiceRecordConfig.sampleRate,
      'bits': 16,
      'channels': 1,
      'length': 32000,
    });
    _channel!.sink.add(start);

    try {
      await _startedCompleter!.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      _utteranceActive = false;
      _resetUtteranceAccum();
      return false;
    }

    if (!await _recorder.hasPermission(request: true)) {
      _utteranceActive = false;
      _resetUtteranceAccum();
      return false;
    }

    final stream = await _recorder.startStream(AppVoiceRecordConfig.pcm16kMono);
    _pcmSub = stream.listen((bytes) {
      unawaited(_sendPcm(bytes));
    });
    return true;
  }

  Future<void> _sendPcm(Uint8List bytes) async {
    if (!_utteranceActive || !isReady || bytes.isEmpty || _feedBusy) return;
    _feedBusy = true;
    try {
      final metrics = pcm16ProcessChunk(bytes, _pcmAbsSession);
      _onLevel?.call(metrics.level);
      _onPcmDiagnostics?.call(
        chunkAvgAbs: metrics.chunkAvgAbs,
        sessionAvgAbs: metrics.sessionAvgAbs,
      );
      _channel?.sink.add(bytes);
    } catch (_) {
      _handleDisconnect();
    } finally {
      _feedBusy = false;
    }
  }

  Future<String> endUtterance() async {
    if (!_utteranceActive) return '';
    await _stopPcm();

    _commitSent = true;
    try {
      _channel?.sink.add(jsonEncode({'type': 'commit'}));
    } catch (_) {}

    var text = '';
    try {
      text = await (_utteranceDone?.future ?? Future.value(_sessionDraft))
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      text = _sessionDraft;
    }

    try {
      _channel?.sink.add(jsonEncode({'type': 'end'}));
    } catch (_) {}

    _utteranceActive = false;
    _onPartial = null;
    final out = preferRicherTranscript(text, _sessionDraft);
    _resetUtteranceAccum();
    return out.trim();
  }

  Future<void> cancelUtterance() async {
    if (!_utteranceActive) return;
    await _stopPcm();
    try {
      _channel?.sink.add(jsonEncode({'type': 'end'}));
    } catch (_) {}
    _utteranceActive = false;
    _onPartial = null;
    _completeUtteranceDone('');
    _resetUtteranceAccum();
  }

  Future<void> dispose() async {
    await cancelUtterance();
    await _tearDownSocket();
    await _recorder.dispose();
    await _readyController.close();
  }
}
