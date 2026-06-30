import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../audio/pcm_level.dart';
import '../config/env.dart';

typedef DeviceNoGetter = String? Function();

const _asrSampleRate = 16000;

/// `/voice/asr/ws`：仅实时转写，无鉴权；`start` 携带 [deviceNo]。
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
  void Function({required int chunkAvgAbs, required int sessionAvgAbs})? _onPcmDiagnostics;
  final _pcmAbsSession = PcmAbsSessionAccumulator();
  Completer<String>? _finalCompleter;
  Completer<void>? _startedCompleter;

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
          _onPartial?.call(text);
        }
      case 'asr_final':
        final text = map['text'] as String? ?? '';
        if (!(_finalCompleter?.isCompleted ?? true)) {
          _finalCompleter!.complete(text);
        }
      case 'asr_no_result':
        if (!(_finalCompleter?.isCompleted ?? true)) {
          _finalCompleter!.complete('');
        }
      case 'ended':
        break;
      case 'error':
        if (!(_startedCompleter?.isCompleted ?? true)) {
          _startedCompleter!.completeError(
            map['message'] as String? ?? 'voice asr error',
          );
        }
        if (!(_finalCompleter?.isCompleted ?? true)) {
          _finalCompleter!.complete('');
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
    void Function({required int chunkAvgAbs, required int sessionAvgAbs})? onPcmDiagnostics,
  }) async {
    if (!await connect()) return false;

    final dn = deviceNoGetter();
    if (dn == null || dn.isEmpty) return false;

    await _stopPcm();
    _pcmAbsSession.reset();
    _onPartial = onPartial;
    _onLevel = onLevel;
    _onPcmDiagnostics = onPcmDiagnostics;
    _finalCompleter = Completer<String>();
    _startedCompleter = Completer<void>();
    _utteranceActive = true;

    final start = jsonEncode({
      'type': 'start',
      'deviceNo': dn,
      'sampleRate': _asrSampleRate,
      'bits': 16,
      'channels': 1,
      'length': 32000,
    });
    _channel!.sink.add(start);

    try {
      await _startedCompleter!.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      _utteranceActive = false;
      return false;
    }

    if (!await _recorder.hasPermission(request: true)) {
      _utteranceActive = false;
      return false;
    }

    final stream = await _recorder.startStream(_recordConfig);
    _pcmSub = stream.listen((bytes) {
      unawaited(_sendPcm(bytes));
    });
    return true;
  }

  static final _recordConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: _asrSampleRate,
    numChannels: 1,
  );

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

    try {
      _channel?.sink.add(jsonEncode({'type': 'commit'}));
    } catch (_) {}

    String text = '';
    try {
      text = await _finalCompleter!.future.timeout(const Duration(seconds: 12));
    } catch (_) {}

    try {
      _channel?.sink.add(jsonEncode({'type': 'end'}));
    } catch (_) {}

    _utteranceActive = false;
    _onPartial = null;
    return text.trim();
  }

  Future<void> cancelUtterance() async {
    if (!_utteranceActive) return;
    await _stopPcm();
    try {
      _channel?.sink.add(jsonEncode({'type': 'end'}));
    } catch (_) {}
    _utteranceActive = false;
    if (!(_finalCompleter?.isCompleted ?? true)) {
      _finalCompleter!.complete('');
    }
  }

  Future<void> dispose() async {
    await cancelUtterance();
    await _tearDownSocket();
    await _recorder.dispose();
    await _readyController.close();
  }
}
