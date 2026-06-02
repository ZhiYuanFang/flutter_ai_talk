import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/toast_bus.dart';
import 'history_mapper.dart';
import 'history_list_page.dart';
import 'home_history_store.dart';
import 'models.dart';
import 'feed_repository.dart';

typedef DeviceNoGetter = String? Function();

/// 远程 Feed：历史分页、更新、文本对话、WebSocket（构造参数 [wsUrl] 非空时建连）。
class RemoteFeedRepository implements FeedRepository {
  RemoteFeedRepository({
    required ApiClient api,
    required DeviceNoGetter deviceNoGetter,
    required String wsUrl,
    required Ref ref,
  })  : _api = api,
        _deviceNoGetter = deviceNoGetter,
        _wsUrl = wsUrl,
        _ref = ref;

  final ApiClient _api;
  final DeviceNoGetter _deviceNoGetter;
  final String _wsUrl;
  final Ref _ref;

  final List<HistoryRecord> _cache = [];
  final StreamController<SseHistoryPayload> _controller = StreamController<SseHistoryPayload>.broadcast();
  final StreamController<bool> _wsReadyController = StreamController<bool>.broadcast();
  final StreamController<HistoryWsPhase> _phaseController =
      StreamController<HistoryWsPhase>.broadcast();
  final _rng = Random();

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _authTimeoutTimer;
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  Completer<void>? _pongCompleter;
  var _wsReady = false;
  HistoryWsPhase _phase = HistoryWsPhase.disconnected;
  var _consecutiveFailedAttempts = 0;
  var _backoffIndex = 0;
  var _missedPongs = 0;
  var _authOkReceived = false;
  var _handshakeAttemptActive = false;
  var _watchSubscribed = false;
  var _attemptGeneration = 0;
  Future<void>? _connectInFlight;

  void _toast(String m) {
    _ref.showApiToastError(m);
  }

  void _emitWsReady(bool v) {
    if (_wsReady == v) return;
    _wsReady = v;
    if (!_wsReadyController.isClosed) {
      _wsReadyController.add(v);
    }
  }

  @override
  bool get isHistoryWebSocketReady =>
      _wsUrl.isNotEmpty &&
      (_deviceNoGetter()?.isNotEmpty ?? false) &&
      _wsReady;

  @override
  Stream<bool> get historyWsReadyStream => _wsReadyController.stream;

  @override
  Stream<HistoryWsPhase> get historyWsPhaseStream => _phaseController.stream;

  @override
  HistoryWsPhase get historyWsPhase => _phase;

  void _emitPhase(HistoryWsPhase next) {
    if (_phase == next) return;
    _phase = next;
    if (!_phaseController.isClosed) {
      _phaseController.add(next);
    }
  }

  void _resetStrike() {
    _consecutiveFailedAttempts = 0;
    _backoffIndex = 0;
    if (_phase == HistoryWsPhase.gaveUp) {
      _emitPhase(HistoryWsPhase.disconnected);
    }
  }

  @override
  void resetHistoryWebSocketStrike() => _resetStrike();

  @override
  void onAppLifecycleResumed() {
    if (_phase == HistoryWsPhase.gaveUp) return;
    if (_wsReady) return;
    if (!_watchSubscribed) return;
    if (_handshakeAttemptActive || _reconnectTimer != null) return;
    _scheduleReconnect();
  }

  void _mergeInbound(HistoryRecord incoming) {
    final i = _cache.indexWhere((e) => e.id == incoming.id);
    if (i >= 0) {
      _cache[i] = incoming;
    } else {
      _cache.add(incoming);
    }
    if (!_controller.isClosed) {
      _controller.add(SseHistoryPayload(record: incoming));
    }
  }

  void _removeFromCache(String id) {
    _cache.removeWhere((e) => e.id == id);
    if (!_controller.isClosed) {
      _controller.add(SseHistoryPayload(record: null, removedRecordId: id));
    }
  }

  void _cancelTimers() {
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
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

  void _logWs(String message) {
    HomeHistoryLog.d('ws $message');
  }

  /// 建连前若 access 将过期/已过期则静默 refresh；失败则登出并清理本地会话相关状态。
  Future<String?> _prepareAccessTokenForConnect() async {
    final session = _ref.read(sessionProvider);
    if (!session.isLoggedIn) {
      return null;
    }
    final ok = await session.ensureFreshSession();
    if (!ok) {
      _logWs('session refresh failed, signed out');
      await _ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await _ref.read(signInChannelProvider.notifier).clear();
      _ref.showApiToastError('登录已过期，请重新登录');
      return null;
    }
    return _ref.read(sessionProvider).accessToken;
  }

  void _tearDownWs({bool scheduleReconnect = false}) {
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
    _emitWsReady(false);
    if (_phase == HistoryWsPhase.ready || _phase == HistoryWsPhase.autoReconnecting) {
      _emitPhase(HistoryWsPhase.disconnected);
    }
    if (scheduleReconnect && _phase != HistoryWsPhase.gaveUp) {
      _scheduleReconnect();
    }
  }

  void _ensureWs() {
    if (_wsUrl.isEmpty) {
      _emitWsReady(false);
      _emitPhase(HistoryWsPhase.disconnected);
      return;
    }
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _emitWsReady(false);
      _emitPhase(HistoryWsPhase.disconnected);
      return;
    }
    if (_phase == HistoryWsPhase.gaveUp) return;
    if (_wsReady) return;
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
    if (_phase == HistoryWsPhase.gaveUp) return;
    if (_handshakeAttemptActive) return;
    if (_wsUrl.isEmpty) return;
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _logWs('skip connect: deviceNo empty');
      return;
    }
    final token = await _prepareAccessTokenForConnect();
    if (token == null || token.isEmpty) {
      _logWs('skip connect: accessToken unavailable');
      return;
    }

    final gen = ++_attemptGeneration;
    _handshakeAttemptActive = true;
    _authOkReceived = false;
    _missedPongs = 0;
    _emitWsReady(false);
    _emitPhase(HistoryWsPhase.autoReconnecting);
    _cancelTimers();
    _wsSub?.cancel();
    _wsSub = null;
    try {
      await _ws?.sink.close();
    } catch (_) {}
    _ws = null;

    _logWs('connect start gen=$gen url=$_wsUrl deviceNo=$dn');
    try {
      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (e) {
          _logWs('stream error gen=$gen: $e');
          if (gen != _attemptGeneration) return;
          if (_handshakeAttemptActive) {
            _failCurrentAttempt(scheduleReconnect: true);
          } else {
            _tearDownWs(scheduleReconnect: true);
          }
        },
        onDone: () {
          _logWs('stream done gen=$gen');
          if (gen != _attemptGeneration) return;
          if (_handshakeAttemptActive) {
            _failCurrentAttempt(scheduleReconnect: true);
          } else {
            _tearDownWs(scheduleReconnect: true);
          }
        },
        cancelOnError: true,
      );
      // 与联调页 onopen 后再发 auth 一致；握手完成前 sink.add 可能丢帧。
      await _ws!.ready.timeout(const Duration(seconds: 15));
      if (gen != _attemptGeneration) return;
      final first = jsonEncode({
        'type': 'auth',
        'accessToken': token,
        'deviceNo': dn,
      });
      _ws!.sink.add(first);
      _logWs('auth sent gen=$gen');
      _authTimeoutTimer?.cancel();
      _authTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (gen != _attemptGeneration) return;
        if (!_authOkReceived && _handshakeAttemptActive) {
          _logWs('auth timeout gen=$gen');
          _failCurrentAttempt(scheduleReconnect: true);
        }
      });
    } catch (e) {
      if (gen != _attemptGeneration) return;
      _logWs('connect failed gen=$gen: $e');
      _handshakeAttemptActive = false;
      _ws = null;
      _emitWsReady(false);
      _recordAttemptFailure();
      if (_phase != HistoryWsPhase.gaveUp) {
        _scheduleReconnect();
      }
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final decoded = _decodeWsMap(raw);
      if (decoded is! Map<String, dynamic>) return;
      final type = _frameType(decoded['type']);
      if (type == 'error') {
        _toast(decoded['message'] as String? ?? '连接异常');
        _failCurrentAttempt(scheduleReconnect: true);
        return;
      }
      if (type == 'pong') {
        _onPongReceived();
        return;
      }
      if (type == 'auth_ok' || type == 'authok') {
        _logWs('auth_ok');
        _onAuthOk();
        return;
      }
      if (!_wsReady) return;
      final action = decoded['action'] as String?;
      if (action == 'delete') {
        final p = decoded['payload'];
        if (p is Map<String, dynamic>) {
          final idRaw = p['id'];
          final idStr = idRaw == null ? '' : idRaw.toString();
          if (idStr.isEmpty) return;
          _removeFromCache(idStr);
        }
        return;
      }
      if (action == 'create' || action == 'update') {
        final p = decoded['payload'];
        if (p is Map<String, dynamic>) {
          _mergeInbound(historyRecordFromServerMap(p));
        }
        return;
      }
      Map<String, dynamic>? map;
      map = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded['payload'] is Map<String, dynamic>
              ? decoded['payload'] as Map<String, dynamic>
              : decoded;
      if (!map.containsKey('id')) return;
      _mergeInbound(historyRecordFromServerMap(map));
    } catch (_) {}
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
      _logWs('handshake pong failed gen=$gen');
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
      _logWs('ping send failed: $e');
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
      if (isHandshake) {
        _failCurrentAttempt(scheduleReconnect: true);
      }
      return false;
    }
  }

  void _onPongReceived() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    final c = _pongCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _pongCompleter = null;
    _missedPongs = 0;

    if (_handshakeAttemptActive && _authOkReceived && !_wsReady) {
      _handshakeAttemptActive = false;
      _consecutiveFailedAttempts = 0;
      _backoffIndex = 0;
      _emitWsReady(true);
      _emitPhase(HistoryWsPhase.ready);
      _logWs('ready (auth_ok + pong)');
      _startPeriodicPing();
      return;
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
      _tearDownWs(scheduleReconnect: true);
    }
  }

  void _startPeriodicPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!_wsReady || _phase == HistoryWsPhase.gaveUp) return;
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
    _emitWsReady(false);
    if (wasHandshake) {
      _recordAttemptFailure();
    }
    if (scheduleReconnect && _phase != HistoryWsPhase.gaveUp) {
      _emitPhase(HistoryWsPhase.disconnected);
      _scheduleReconnect();
    }
  }

  void _recordAttemptFailure() {
    _consecutiveFailedAttempts++;
    _logWs('attempt failed strike=$_consecutiveFailedAttempts/3');
    if (_consecutiveFailedAttempts >= 3) {
      _cancelReconnectTimer();
      _emitPhase(HistoryWsPhase.gaveUp);
      _logWs('gave up');
    }
  }

  void _scheduleReconnect() {
    if (_phase == HistoryWsPhase.gaveUp) return;
    if (!_watchSubscribed) return;
    if (_reconnectTimer != null) return;
    _emitPhase(HistoryWsPhase.autoReconnecting);
    final baseMs = min(1000 * (1 << _backoffIndex), 30000);
    final jitterMs = _rng.nextInt(501);
    final delay = Duration(milliseconds: baseMs + jitterMs);
    _backoffIndex++;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_phase == HistoryWsPhase.gaveUp) return;
      unawaited(_beginAttempt());
    });
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

  @override
  Future<void> reconnectHistoryWebSocket({bool resetStrike = false}) async {
    if (resetStrike) _resetStrike();
    _logWs('manual reconnect resetStrike=$resetStrike phase=$_phase');
    _connectInFlight = null;
    _cancelReconnectTimer();
    _tearDownWs(scheduleReconnect: false);
    if (_phase == HistoryWsPhase.gaveUp) return;
    await _beginAttemptOnce();
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
    await HomeHistoryStore.clearAll();
  }

  @override
  Future<List<HistoryRecord>> loadHistory() async {
    final result = await tryLoadHistory();
    if (result == null) return [];
    return result;
  }

  @override
  Future<List<HistoryRecord>?> tryLoadHistory() async {
    final page = await tryLoadHistoryPage(page: 1);
    if (page == null) return null;
    return page.listDesc;
  }

  @override
  Future<HistoryListPage?> tryLoadHistoryPage({
    required int page,
    int pageSize = kHomeHistoryPageSize,
  }) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      HomeHistoryLog.d('api list skip: deviceNo empty');
      return const HistoryListPage(
        listDesc: [],
        total: 0,
        page: 1,
        pageSize: kHomeHistoryPageSize,
      );
    }
    HomeHistoryLog.d('api list start deviceNo=$dn page=$page pageSize=$pageSize');
    final sw = Stopwatch()..start();
    try {
      final data = await _api.getEnvelope(
        '/device/history/api/list',
        query: {
          'deviceNo': dn,
          'page': '$page',
          'pageSize': '$pageSize',
        },
      );
      if (data == null) {
        sw.stop();
        HomeHistoryLog.d('api list response data=null elapsed=${sw.elapsedMilliseconds}ms');
        return null;
      }
      final list = data['list'] as List<dynamic>? ?? const [];
      final out = <HistoryRecord>[];
      for (final e in list) {
        if (e is Map) {
          out.add(historyRecordFromServerMap(Map<String, dynamic>.from(e)));
        }
      }
      if (page == 1) {
        _cache
          ..clear()
          ..addAll(out);
      } else {
        for (final r in out) {
          if (!_cache.any((e) => e.id == r.id)) {
            _cache.add(r);
          }
        }
      }
      final totalRaw = data['total'];
      final total = totalRaw is num ? totalRaw.toInt() : out.length;
      final pageRaw = data['page'];
      final pageNo = pageRaw is num ? pageRaw.toInt() : page;
      final pageSizeRaw = data['pageSize'];
      final resolvedPageSize =
          pageSizeRaw is num ? pageSizeRaw.toInt() : pageSize;
      sw.stop();
      HomeHistoryLog.d(
        'api list ok page=$pageNo count=${out.length} total=$total '
        'elapsed=${sw.elapsedMilliseconds}ms',
      );
      return HistoryListPage(
        listDesc: out,
        total: total,
        page: pageNo,
        pageSize: resolvedPageSize,
      );
    } on ApiBusinessException catch (e) {
      sw.stop();
      HomeHistoryLog.d(
        'api list ApiBusinessException code=${e.code} message=${e.message} elapsed=${sw.elapsedMilliseconds}ms',
      );
      return null;
    } catch (e) {
      sw.stop();
      HomeHistoryLog.d('api list error: $e elapsed=${sw.elapsedMilliseconds}ms');
      return null;
    }
  }

  @override
  Future<HistoryRecord?> getRecord(String id) async {
    for (final e in _cache) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _ensureDeviceNoOnBody(Map<String, dynamic> body) {
    final dn = body['deviceNo']?.toString() ?? '';
    if (dn.isEmpty) {
      final g = _deviceNoGetter();
      if (g != null && g.isNotEmpty) {
        body['deviceNo'] = g;
      }
    }
  }

  @override
  Future<bool> updateHistoryRecord(
    String id, {
    required String remark,
    DateTime? startTime,
    DateTime? endTime,
    int? usageCount,
    bool clearEndIfNull = false,
    HistoryRecord? fallbackRecord,
  }) async {
    final existing = await getRecord(id) ?? fallbackRecord;
    if (existing == null) return false;
    final body = buildEventUpdateBody(
      record: existing,
      remark: remark,
      startTime: startTime,
      endTime: endTime,
      usageCount: usageCount,
      clearEndIfNull: clearEndIfNull,
    );
    _ensureDeviceNoOnBody(body);
    try {
      await _api.postJsonEnvelope('/device/history/api/event/update', body);
      return true;
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return false;
    }
  }

  @override
  Future<String?> addHistoryEvent(Map<String, dynamic> body) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _toast('请先绑定宝宝信息');
      return null;
    }
    if (!isHistoryWebSocketReady) {
      return null;
    }
    final payload = Map<String, dynamic>.from(body);
    _ensureDeviceNoOnBody(payload);
    try {
      final data = await _api.postJsonEnvelope('/device/history/api/event/add', payload);
      if (data == null) {
        _toast('响应无数据');
        return null;
      }
      final idRaw = data['id'];
      if (idRaw == null) {
        _toast('响应无记录 id');
        return null;
      }
      return idRaw.toString();
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return null;
    } catch (_) {
      _toast('网络异常');
      return null;
    }
  }

  @override
  Future<bool> deleteHistoryRecord(String id) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _toast('请先绑定宝宝信息');
      return false;
    }
    final idInt = int.tryParse(id) ?? 0;
    if (idInt == 0) {
      _toast('记录 id 无效');
      return false;
    }
    try {
      await _api.postJsonEnvelope('/device/history/api/event/delete', {
        'id': idInt,
        'deviceNo': dn,
      });
      _removeFromCache(id);
      return true;
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return false;
    }
  }

  @override
  Future<String?> sendCommand(String text) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _toast('请先绑定宝宝信息');
      return null;
    }
    if (!isHistoryWebSocketReady) {
      return null;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final data = await _api.postJsonEnvelope(
        '/device/history/api/chat',
        {'deviceNo': dn, 'transcript': trimmed},
      );
      return data?['reply'] as String?;
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return null;
    }
  }

  @override
  Stream<SseHistoryPayload> watchLatest() {
    _watchSubscribed = true;
    _ensureWs();
    return _controller.stream;
  }

  void dispose() {
    _watchSubscribed = false;
    _cancelReconnectTimer();
    _tearDownWs(scheduleReconnect: false);
    if (!_wsReadyController.isClosed) {
      _wsReadyController.close();
    }
    if (!_phaseController.isClosed) {
      _phaseController.close();
    }
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
