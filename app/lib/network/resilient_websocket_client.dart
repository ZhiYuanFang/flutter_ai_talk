import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'ws_connection_config.dart';
import 'ws_connection_phase.dart';

/// 共享 WebSocket 传输：鉴权、JSON ping/pong、指数退避、gaveUp、resume 重连。
class ResilientWebSocketClient {
  ResilientWebSocketClient(this._config);

  final WsConnectionConfig _config;
  final _rng = Random();

  final _readyController = StreamController<bool>.broadcast();
  final _phaseController = StreamController<WsConnectionPhase>.broadcast();

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _authTimeoutTimer;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  Completer<void>? _pongCompleter;
  var _ready = false;
  var _phase = WsConnectionPhase.disconnected;
  var _consecutiveFailedAttempts = 0;
  var _backoffIndex = 0;
  var _missedPongs = 0;
  var _authOkReceived = false;
  var _handshakeAttemptActive = false;
  var _connectionDesired = false;
  var _subscribeActive = true;
  var _attemptGeneration = 0;
  Future<void>? _connectInFlight;

  Stream<bool> get readyStream => _readyController.stream;
  Stream<WsConnectionPhase> get phaseStream => _phaseController.stream;
  bool get isReady => _ready;
  WsConnectionPhase get phase => _phase;

  void _log(String message) {
    _config.log?.call('${_config.channelLabel} $message');
  }

  void _emitReady(bool v) {
    if (_ready == v) return;
    _ready = v;
    if (!_readyController.isClosed) _readyController.add(v);
  }

  void _emitPhase(WsConnectionPhase next) {
    if (_phase == next) return;
    _phase = next;
    if (!_phaseController.isClosed) _phaseController.add(next);
  }

  void setConnectionDesired(bool desired) {
    _connectionDesired = desired;
    if (desired) {
      _ensureConnect();
    } else {
      _connectInFlight = null;
      _cancelReconnectTimer();
      _tearDown(scheduleReconnect: false);
    }
  }

  /// 喂养历史：watchLatest 订阅后才允许自动重连。
  void setSubscribeActive(bool active) {
    _subscribeActive = active;
    if (!active) {
      _cancelReconnectTimer();
      _tearDown(scheduleReconnect: false);
    } else if (_connectionDesired) {
      _ensureConnect();
    }
  }

  void resetStrike() {
    _consecutiveFailedAttempts = 0;
    _backoffIndex = 0;
    if (_phase == WsConnectionPhase.gaveUp) {
      _emitPhase(WsConnectionPhase.disconnected);
    }
  }

  void onAppLifecycleResumed() {
    if (_phase == WsConnectionPhase.gaveUp) return;
    if (_ready) return;
    if (!_connectionDesired) return;
    if (!_mayAutoReconnect()) return;
    if (_handshakeAttemptActive || _reconnectTimer != null) return;
    _scheduleReconnect();
  }

  Future<void> reconnect({bool resetStrike = false}) async {
    if (resetStrike) this.resetStrike();
    _log('manual reconnect resetStrike=$resetStrike phase=$_phase');
    _connectInFlight = null;
    _cancelReconnectTimer();
    _tearDown(scheduleReconnect: false);
    if (_phase == WsConnectionPhase.gaveUp) return;
    await _beginAttemptOnce();
  }

  void sendJson(Map<String, dynamic> payload) {
    _ws?.sink.add(jsonEncode(payload));
  }

  void dispose() {
    setConnectionDesired(false);
    if (!_readyController.isClosed) _readyController.close();
    if (!_phaseController.isClosed) _phaseController.close();
  }

  bool _mayAutoReconnect() {
    if (_config.requireSubscribeGate && !_subscribeActive) return false;
    return true;
  }

  void _ensureConnect() {
    if (!_connectionDesired) return;
    if (_config.url.isEmpty) {
      _emitReady(false);
      _emitPhase(WsConnectionPhase.disconnected);
      return;
    }
    if (_phase == WsConnectionPhase.gaveUp) return;
    if (_ready) return;
    if (_handshakeAttemptActive) return;
    if (_reconnectTimer != null) return;
    if (_connectInFlight != null) return;
    unawaited(_beginAttempt());
  }

  Future<void> _beginAttempt() async {
    if (_connectInFlight != null) {
      await _connectInFlight;
      return;
    }
    _connectInFlight = _beginAttemptOnce();
    try {
      await _connectInFlight;
    } finally {
      _connectInFlight = null;
    }
  }

  Future<void> _beginAttemptOnce() async {
    if (_phase == WsConnectionPhase.gaveUp) return;
    if (_handshakeAttemptActive) return;
    if (!_connectionDesired) return;
    if (_config.url.isEmpty) return;

    final canConnect = await _config.shouldConnect();
    if (!canConnect) {
      _log('skip connect: shouldConnect false');
      return;
    }

    final ctx = await _config.prepareToken();
    if (ctx == null || (ctx.accessToken == null || ctx.accessToken!.isEmpty)) {
      _log('skip connect: token unavailable');
      return;
    }

    final gen = ++_attemptGeneration;
    _handshakeAttemptActive = true;
    _authOkReceived = false;
    _missedPongs = 0;
    _emitReady(false);
    _emitPhase(WsConnectionPhase.autoReconnecting);
    _cancelTimers();
    _wsSub?.cancel();
    _wsSub = null;
    try {
      await _ws?.sink.close();
    } catch (_) {}
    _ws = null;

    _log('connect start gen=$gen url=${_config.url}');
    try {
      _ws = WebSocketChannel.connect(Uri.parse(_config.url));
      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (e) {
          _log('stream error gen=$gen: $e');
          if (gen != _attemptGeneration) return;
          if (_handshakeAttemptActive) {
            _failCurrentAttempt(scheduleReconnect: true);
          } else {
            _tearDown(scheduleReconnect: true);
          }
        },
        onDone: () {
          _log('stream done gen=$gen');
          if (gen != _attemptGeneration) return;
          if (_handshakeAttemptActive) {
            _failCurrentAttempt(scheduleReconnect: true);
          } else {
            _tearDown(scheduleReconnect: true);
          }
        },
        cancelOnError: true,
      );
      await _ws!.ready.timeout(const Duration(seconds: 15));
      if (gen != _attemptGeneration) return;
      final authFrame = _config.buildAuthFrame(ctx);
      _ws!.sink.add(jsonEncode(authFrame));
      _log('auth sent gen=$gen');
      _authTimeoutTimer?.cancel();
      _authTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (gen != _attemptGeneration) return;
        if (!_authOkReceived && _handshakeAttemptActive) {
          _log('auth timeout gen=$gen');
          _failCurrentAttempt(scheduleReconnect: true);
        }
      });
    } catch (e) {
      if (gen != _attemptGeneration) return;
      _log('connect failed gen=$gen: $e');
      _handshakeAttemptActive = false;
      _ws = null;
      _emitReady(false);
      _recordAttemptFailure();
      if (_phase != WsConnectionPhase.gaveUp) {
        _scheduleReconnect();
      }
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final decoded = _decodeWsMap(raw);
      if (decoded is! Map<String, dynamic>) {
        _log('ws drop reason=decode_not_map rawType=${raw.runtimeType}');
        return;
      }
      final type = _frameType(decoded['type']);
      if (type == 'error') {
        _log(
          'ws error frame message=${decoded['message']} '
          'code=${decoded['code']} keys=${decoded.keys.join(',')}',
        );
        unawaited(_handleErrorFrame(decoded));
        return;
      }
      if (type == 'pong') {
        _onPongReceived();
        return;
      }
      if (type == 'auth_ok' || type == 'authok') {
        _log('auth_ok');
        _onAuthOk();
        return;
      }
      final action = decoded['action'];
      _log(
        'ws raw type=$type action=$action ready=$_ready '
        'keys=${decoded.keys.join(',')}',
      );
      if (!_ready) {
        _log('ws drop reason=not_ready type=$type action=$action');
        return;
      }
      _config.onApplicationFrame?.call(decoded);
    } catch (e) {
      _log('ws drop reason=decode_error err=$e');
    }
  }

  Future<void> _handleErrorFrame(Map<String, dynamic> decoded) async {
    final schedule = await _config.onErrorFrame?.call(decoded) ?? true;
    _failCurrentAttempt(scheduleReconnect: schedule);
  }

  void _onAuthOk() {
    if (!_handshakeAttemptActive) return;
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = null;
    _authOkReceived = true;
    unawaited(_finishHandshakePingPong());
  }

  Future<void> _finishHandshakePingPong() async {
    final gen = _attemptGeneration;
    final ok = await _sendPing(expectResponse: true, isHandshake: true);
    if (gen != _attemptGeneration) return;
    if (!ok) {
      _log('handshake pong failed gen=$gen');
      _failCurrentAttempt(scheduleReconnect: true);
    }
  }

  Future<bool> _sendPing({required bool expectResponse, bool isHandshake = false}) async {
    if (_ws == null) {
      if (isHandshake) _failCurrentAttempt(scheduleReconnect: true);
      return false;
    }
    Completer<void>? waiter;
    if (expectResponse) {
      _cancelPongWait();
      waiter = Completer<void>();
      _pongCompleter = waiter;
    }
    try {
      _ws!.sink.add(jsonEncode({'type': 'ping'}));
    } catch (e) {
      _log('ping send failed: $e');
      if (isHandshake) {
        _failCurrentAttempt(scheduleReconnect: true);
      } else {
        _onPongTimeout(isHandshake: false);
      }
      return false;
    }
    if (!expectResponse || waiter == null) return true;
    try {
      await waiter.future.timeout(const Duration(seconds: 8));
      return true;
    } on TimeoutException {
      _onPongTimeout(isHandshake: isHandshake);
      return false;
    } catch (_) {
      if (isHandshake) _failCurrentAttempt(scheduleReconnect: true);
      return false;
    }
  }

  void _onPongReceived() {
    final c = _pongCompleter;
    if (c != null && !c.isCompleted) c.complete();
    _pongCompleter = null;
    _missedPongs = 0;

    if (_handshakeAttemptActive && _authOkReceived && !_ready) {
      _handshakeAttemptActive = false;
      _consecutiveFailedAttempts = 0;
      _backoffIndex = 0;
      _emitReady(true);
      _emitPhase(WsConnectionPhase.ready);
      _log('ready (auth_ok + pong)');
      _startPeriodicPing();
    }
  }

  void _onPongTimeout({required bool isHandshake}) {
    _cancelPongWait();
    if (isHandshake) {
      _failCurrentAttempt(scheduleReconnect: true);
      return;
    }
    _missedPongs++;
    if (_missedPongs >= 2) {
      _missedPongs = 0;
      _tearDown(scheduleReconnect: true);
    }
  }

  void _startPeriodicPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!_ready || _phase == WsConnectionPhase.gaveUp) return;
      unawaited(_sendPing(expectResponse: true));
    });
  }

  void _failCurrentAttempt({required bool scheduleReconnect}) {
    final wasHandshake = _handshakeAttemptActive;
    if (!wasHandshake && !scheduleReconnect) return;
    _invalidateInFlightAttempt();
    _authOkReceived = false;
    _cancelTimers();
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    _emitReady(false);
    if (wasHandshake) _recordAttemptFailure();
    if (scheduleReconnect && _phase != WsConnectionPhase.gaveUp) {
      _emitPhase(WsConnectionPhase.disconnected);
      _scheduleReconnect();
    }
  }

  void _recordAttemptFailure() {
    _consecutiveFailedAttempts++;
    _log('attempt failed strike=$_consecutiveFailedAttempts/3');
    if (_consecutiveFailedAttempts >= 3) {
      _cancelReconnectTimer();
      _emitPhase(WsConnectionPhase.gaveUp);
      _log('gave up');
    }
  }

  void _scheduleReconnect() {
    if (_phase == WsConnectionPhase.gaveUp) return;
    if (!_connectionDesired) return;
    if (!_mayAutoReconnect()) return;
    if (_reconnectTimer != null) return;
    _emitPhase(WsConnectionPhase.autoReconnecting);
    final baseMs = min(1000 * (1 << _backoffIndex), 30000);
    final jitterMs = _rng.nextInt(501);
    final delay = Duration(milliseconds: baseMs + jitterMs);
    _backoffIndex++;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_phase == WsConnectionPhase.gaveUp) return;
      unawaited(_beginAttempt());
    });
  }

  void _tearDown({required bool scheduleReconnect}) {
    _invalidateInFlightAttempt();
    _authOkReceived = false;
    _missedPongs = 0;
    _cancelTimers();
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    _emitReady(false);
    if (_phase == WsConnectionPhase.ready || _phase == WsConnectionPhase.autoReconnecting) {
      _emitPhase(WsConnectionPhase.disconnected);
    }
    if (scheduleReconnect && _phase != WsConnectionPhase.gaveUp) {
      _scheduleReconnect();
    }
  }

  void _cancelTimers() {
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _cancelPongWait();
  }

  void _cancelPongWait() {
    final c = _pongCompleter;
    if (c != null && !c.isCompleted) {
      c.completeError(StateError('cancelled'));
    }
    _pongCompleter = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _invalidateInFlightAttempt() {
    _attemptGeneration++;
    _handshakeAttemptActive = false;
  }

  String? _frameType(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final t = raw.trim().toLowerCase();
      return t.isEmpty ? null : t;
    }
    return raw.toString().trim().toLowerCase();
  }

  Map<String, dynamic>? _decodeWsMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    Object? decoded;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      decoded = jsonDecode(s);
    } else if (raw is List<int>) {
      decoded = jsonDecode(utf8.decode(raw));
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }
}
