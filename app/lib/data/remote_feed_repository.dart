import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ai_quota_codes.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../network/resilient_websocket_client.dart';
import '../network/ws_connection_config.dart';
import '../network/ws_phase_mapping.dart';
import '../providers/ai_quota_dialog_bus.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/toast_bus.dart';
import '../session/session_device_token_sync.dart';
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
        _ref = ref {
    _wsClient = ResilientWebSocketClient(
      WsConnectionConfig(
        url: _wsUrl,
        channelLabel: 'history',
        requireSubscribeGate: true,
        shouldConnect: () async {
          if (_wsUrl.isEmpty) return false;
          final dn = _deviceNoGetter();
          return dn != null && dn.isNotEmpty;
        },
        prepareToken: _prepareWsConnectContext,
        buildAuthFrame: (ctx) => {
          'type': 'auth',
          'accessToken': ctx.accessToken,
          'deviceNo': ctx.deviceNo,
        },
        onApplicationFrame: _onHistoryApplicationFrame,
        onErrorFrame: _onHistoryWsError,
        log: _logWs,
      ),
    );
    _wsClient.readyStream.listen(_emitWsReady);
    _wsClient.phaseStream.listen((p) => _emitPhase(historyWsPhaseFromShared(p)));
  }

  final ApiClient _api;
  final DeviceNoGetter _deviceNoGetter;
  final String _wsUrl;
  final Ref _ref;

  final List<HistoryRecord> _cache = [];
  final StreamController<SseHistoryPayload> _controller = StreamController<SseHistoryPayload>.broadcast();
  final StreamController<bool> _wsReadyController = StreamController<bool>.broadcast();
  final StreamController<HistoryWsPhase> _phaseController =
      StreamController<HistoryWsPhase>.broadcast();
  late final ResilientWebSocketClient _wsClient;
  HistoryWsPhase _phase = HistoryWsPhase.disconnected;
  var _wsReady = false;

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
    _wsClient.resetStrike();
    if (_phase == HistoryWsPhase.gaveUp) {
      _emitPhase(HistoryWsPhase.disconnected);
    }
  }

  @override
  void resetHistoryWebSocketStrike() => _resetStrike();

  @override
  void onAppLifecycleResumed() => _wsClient.onAppLifecycleResumed();

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

  void _logWs(String message) {
    HomeHistoryLog.d(message);
  }

  Future<WsConnectContext?> _prepareWsConnectContext() async {
    final session = _ref.read(sessionProvider);
    if (!session.isLoggedIn) return null;
    final ok = await session.ensureFreshSession();
    if (!ok) {
      _logWs('ws session refresh failed, signed out');
      await _ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await _ref.read(signInChannelProvider.notifier).clear();
      if (_ref.read(homeHistoryProvider).initialLoadDone) {
        _ref.showApiToastError('登录已过期，请重新登录');
      }
      return null;
    }
    final dn = _deviceNoGetter();
    if (dn != null && dn.isNotEmpty) {
      final synced = await ensureAccessTokenHasDeviceNo(_ref, localDeviceNo: dn);
      if (!synced) {
        _logWs('ws token refresh for device_no failed');
        _ref.showApiToastError('会话刷新失败，请重新登录后再试');
        return null;
      }
    }
    return WsConnectContext(
      accessToken: _ref.read(sessionProvider).accessToken,
      deviceNo: dn,
    );
  }

  Future<bool> _onHistoryWsError(Map<String, dynamic> decoded) async {
    final bizCode = parseWsErrorBusinessCode(decoded);
    if (bizCode != null && isAiQuotaBusinessCode(bizCode)) {
      _ref.requestAiQuotaDialog(bizCode);
      return false;
    }
    _toast(decoded['message'] as String? ?? '连接异常');
    return true;
  }

  void _onHistoryApplicationFrame(Map<String, dynamic> decoded) {
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
    final map = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded['payload'] is Map<String, dynamic>
            ? decoded['payload'] as Map<String, dynamic>
            : decoded;
    if (!map.containsKey('id')) return;
    _mergeInbound(historyRecordFromServerMap(map));
  }

  void _ensureWs() {
    _wsClient.setConnectionDesired(true);
  }

  @override
  Future<void> reconnectHistoryWebSocket({bool resetStrike = false}) async {
    _wsClient.setConnectionDesired(true);
    await _wsClient.reconnect(resetStrike: resetStrike);
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
    int? postId,
    int? mediaType,
    List<String>? imageKeys,
    String? videoKey,
    bool patchMediaFields = false,
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
      postId: postId,
      mediaType: mediaType,
      imageKeys: imageKeys,
      videoKey: videoKey,
      patchMediaFields: patchMediaFields,
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
      // 喂养 AI 额度/登录错误交由 UI 层弹框（与 WS error 帧一致）。
      if (isAiQuotaBusinessCode(e.code)) rethrow;
      _toast(e.message);
      return null;
    }
  }

  @override
  Stream<SseHistoryPayload> watchLatest() {
    _wsClient.setSubscribeActive(true);
    _ensureWs();
    return _controller.stream;
  }

  void dispose() {
    _wsClient.setSubscribeActive(false);
    _wsClient.dispose();
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
