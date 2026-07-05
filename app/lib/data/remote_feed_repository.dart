import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ai_quota_codes.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../config/env.dart';
import '../network/resilient_websocket_client.dart';
import '../network/ws_auth_error_handler.dart';
import '../network/ws_connect_context.dart';
import '../network/ws_connection_config.dart';
import '../network/ws_phase_mapping.dart';
import '../providers/ai_quota_dialog_bus.dart';
import '../providers/toast_bus.dart';
import '../api/app_debug_log.dart';
import 'history_mapper.dart';
import 'history_outbox_flusher.dart';
import 'history_outbox_store.dart';
import 'history_post_outcome.dart';
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
    final wasReady = _wsReady;
    if (_wsReady == v) return;
    _wsReady = v;
    if (!_wsReadyController.isClosed) {
      _wsReadyController.add(v);
    }
    if (!wasReady && v) {
      unawaited(flushHistoryOutbox(_ref));
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

  Future<WsConnectContext?> _prepareWsConnectContext() => prepareDeviceWsConnectContext(
        _ref,
        deviceNo: _deviceNoGetter(),
        shouldToastHardFailure: () => historyWsShouldToastHardFailure(_ref),
      );

  Future<bool> _onHistoryWsError(Map<String, dynamic> decoded) async {
    final result = await handleWsAuthOrQuotaError(
      _ref,
      decoded,
      onQuotaDialog: (c) => _ref.requestAiQuotaDialog(c),
      onGenericError: _toast,
      genericErrorSchedulesReconnect: true,
    );
    if (result.requestLoginDialog) {
      _ref.requestAiQuotaDialog(kAiCodeNotLoggedIn);
    }
    return result.scheduleReconnect;
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
        final record = historyRecordFromServerMap(p);
        _mergeInbound(record);
      }
      return;
    }
    final map = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded['payload'] is Map<String, dynamic>
            ? decoded['payload'] as Map<String, dynamic>
            : decoded;
    if (!map.containsKey('id')) return;
    final record = historyRecordFromServerMap(map);
    _mergeInbound(record);
  }

  void _ensureWs() {
    if (AppEnv.disablePangbaoWebSocketSpike) return;
    _wsClient.setConnectionDesired(true);
  }

  @override
  Future<void> reconnectHistoryWebSocket({bool resetStrike = false}) async {
    if (AppEnv.disablePangbaoWebSocketSpike) return;
    _wsClient.setConnectionDesired(true);
    await _wsClient.reconnect(resetStrike: resetStrike);
  }

  @override
  void disconnectHistoryWebSocket() {
    _wsClient.setSubscribeActive(false);
    _wsClient.setConnectionDesired(false);
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
    await HomeHistoryStore.clearAll();
    await HistoryOutboxStore.clearAll();
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
      return const HistoryListPage(
        listDesc: [],
        total: 0,
        page: 1,
        pageSize: kHomeHistoryPageSize,
      );
    }
    try {
      final data = await _api.getEnvelope(
        '/device/history/api/list',
        query: {
          'deviceNo': dn,
          'page': '$page',
          'pageSize': '$pageSize',
        },
      );
      if (data == null) return null;
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
      return HistoryListPage(
        listDesc: out,
        total: total,
        page: pageNo,
        pageSize: resolvedPageSize,
      );
    } on ApiBusinessException {
      return null;
    } catch (_) {
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
  Future<HistoryAddPostOutcome> addHistoryEvent(Map<String, dynamic> body) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _toast('请先绑定宝宝信息');
      return HistoryAddPostOutcome.failure(HistoryPostFailureKind.deviceUnbound);
    }
    final payload = Map<String, dynamic>.from(body);
    _ensureDeviceNoOnBody(payload);
    try {
      final data = await _api.postJsonEnvelope('/device/history/api/event/add', payload);
      if (data == null) {
        return HistoryAddPostOutcome.failure(HistoryPostFailureKind.transport);
      }
      final idRaw = data['id'];
      if (idRaw == null) {
        return HistoryAddPostOutcome.failure(HistoryPostFailureKind.transport);
      }
      return HistoryAddPostOutcome.success(idRaw.toString());
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return HistoryAddPostOutcome.failure(HistoryPostFailureKind.business);
    } catch (e) {
      AppDebugLog.historyOutbox('add transport err=$e');
      return HistoryAddPostOutcome.failure(HistoryPostFailureKind.transport);
    }
  }

  @override
  Future<HistoryUpdatePostOutcome> postHistoryUpdateBody(Map<String, dynamic> body) async {
    final payload = Map<String, dynamic>.from(body);
    _ensureDeviceNoOnBody(payload);
    try {
      await _api.postJsonEnvelope('/device/history/api/event/update', payload);
      return HistoryUpdatePostOutcome.success();
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return HistoryUpdatePostOutcome.failure(HistoryPostFailureKind.business);
    } catch (e) {
      AppDebugLog.historyOutbox('update transport err=$e');
      return HistoryUpdatePostOutcome.failure(HistoryPostFailureKind.transport);
    }
  }

  @override
  Future<void> enqueueHistoryUpdateOutbox(String recordId, Map<String, dynamic> body) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty || recordId.isEmpty) return;
    await HistoryOutboxStore.enqueueUpdate(
      deviceNo: dn,
      recordId: recordId,
      body: body,
    );
  }

  @override
  Future<void> flushPendingHistoryOutbox() => flushHistoryOutbox(_ref);

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
    if (!isHistoryWebSocketReady) return null;
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
  Future<String?> fetchWidgetFeedingTip() async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) return null;
    try {
      final data = await _api.postJsonEnvelope(
        '/device/history/api/chat',
        {'deviceNo': dn, 'transcript': '接下来需要注意什么？'},
      );
      return data?['reply'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<SseHistoryPayload> watchLatest() {
    _wsClient.setSubscribeActive(true);
    return _controller.stream;
  }

  @override
  void ensureHistoryWebSocketConnected() {
    if (AppEnv.disablePangbaoWebSocketSpike) return;
    _ensureWs();
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
