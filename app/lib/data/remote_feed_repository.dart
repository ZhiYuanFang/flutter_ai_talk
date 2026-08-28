import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

  @override
  Future<({bool ready, HistoryWsPhase phase, String detail})>
      waitForHistoryWsReadyOrTerminal({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final r = await _wsClient.waitForReadyOrTerminal(timeout: timeout);
    return (
      ready: r.ready,
      phase: historyWsPhaseFromShared(r.phase),
      detail: r.detail,
    );
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
  Future<List<HistoryRecord>?> tryLoadHistoryFilter({
    int startTime = 0,
    int endTime = 0,
    int limit = kHistoryFilterMaxLimit,
    String eventIds = '',
  }) async {
    final dn = _deviceNoGetter();
    // 无 deviceNo：失败（null），不得当成成功空列表以免 range ready 锁死
    if (dn == null || dn.isEmpty) return null;
    try {
      final query = <String, String>{
        'deviceNo': dn,
        'eventIds': eventIds,
        'limit': '$limit',
      };
      if (startTime > 0) query['startTime'] = '$startTime';
      if (endTime > 0) query['endTime'] = '$endTime';
      final data = await _api.getEnvelope(
        '/device/history/api/filter',
        query: query,
        timeout: const Duration(seconds: 45),
      );
      if (data == null) return null;
      final list = data['list'] as List<dynamic>? ?? const [];
      final out = <HistoryRecord>[];
      for (final e in list) {
        if (e is Map) {
          out.add(historyRecordFromServerMap(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    } on ApiBusinessException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HistoryListPage?> tryLoadHistoryPageV2({
    int page = 1,
    int pageSize = kHomeHistoryPageSize,
    int startTime = 0,
    int endTime = 0,
    int limit = 0,
  }) async {
    final dn = _deviceNoGetter();
    // 无 deviceNo：失败（null），不得返回成功空页
    if (dn == null || dn.isEmpty) return null;
    try {
      final query = <String, String>{
        'deviceNo': dn,
        'page': '$page',
        'pageSize': '$pageSize',
      };
      if (startTime > 0) query['startTime'] = '$startTime';
      if (endTime > 0) query['endTime'] = '$endTime';
      if (limit > 0) query['limit'] = '$limit';
      final data = await _api.getEnvelope(
        '/device/history/api/v2/list',
        query: query,
        timeout: const Duration(seconds: 45),
      );
      if (data == null) return null;
      final list = data['list'] as List<dynamic>? ?? const [];
      final out = <HistoryRecord>[];
      for (final e in list) {
        if (e is Map) {
          out.add(historyRecordFromServerMap(Map<String, dynamic>.from(e)));
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
      AppDebugLog.wsTransport('history add transport err=$e');
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
      AppDebugLog.wsTransport('history update transport err=$e');
      return HistoryUpdatePostOutcome.failure(HistoryPostFailureKind.transport);
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
  Stream<ChatStreamEvent> sendCommand(String text) async* {
    // 前置条件：deviceNo 非空
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _toast('请先绑定宝宝信息');
      return;
    }
    // 前置条件：WS ready（与同步版本一致）
    if (!isHistoryWebSocketReady) return;
    // 前置条件：文本非空
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 使用 http.Client 发送 SSE 请求
    final client = http.Client();
    try {
      // 构建请求 URL（复用 ApiClient 的 baseUrl 与 token 逻辑）
      final base = Uri.parse(_api.baseUrl);
      final path = base.path.endsWith('/')
          ? '${base.path}device/history/api/chat/stream'
          : '${base.path}/device/history/api/chat/stream';
      final uri = base.replace(path: path);

      // 构建请求体
      final body = jsonEncode({'deviceNo': dn, 'transcript': trimmed});

      // 构建请求
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = body;

      // 添加鉴权头（复用 ApiClient 的 accessTokenProvider）
      final token = _api.accessTokenProvider();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 发送请求并获取流式响应
      final response = await client.send(request);

      // HTTP 非 200：尝试解析业务错误
      if (response.statusCode != 200) {
        final bodyStr = await response.stream.bytesToString();
        // 尝试按 ApiClient 的 {code,message,data} 信封解析
        try {
          final decoded = jsonDecode(bodyStr);
          if (decoded is Map<String, dynamic>) {
            final codeVal = decoded['code'];
            final code = codeVal is int ? codeVal : (codeVal is num ? codeVal.toInt() : -1);
            final message = decoded['message'] as String? ?? '';
            final exc = ApiBusinessException(code, message);
            // AI 额度/登录错误交由 UI 层弹框（与同步版本一致）
            if (isAiQuotaBusinessCode(code)) {
              throw exc;
            }
            _toast(message);
            return;
          }
        } catch (_) {
          // 非 JSON 格式：按 HTTP 错误处理
        }
        throw ApiHttpException(response.statusCode, bodyStr);
      }

      // 逐行解析 SSE 帧
      var currentEvent = ''; // 当前事件类型：thinking / answer
      var buffer = ''; // 行缓冲（处理跨 chunk 的不完整行）

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        // 按换行分割处理完整行
        var lineEnd = 0;
        while ((lineEnd = buffer.indexOf('\n')) != -1) {
          final rawLine = buffer.substring(0, lineEnd);
          buffer = buffer.substring(lineEnd + 1);
          final line = rawLine.trim();
          if (line.isEmpty) continue; // 空行跳过（帧分隔符）

          // event: <type>
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }

          // data: <content>
          if (line.startsWith('data:')) {
            final data = line.substring(5).trim();
            // 结束标记
            if (data == '[DONE]') {
              return;
            }
            // 仅当有当前事件类型时才产出内容
            if (currentEvent == 'thinking') {
              yield ChatStreamEvent(ChatStreamEventType.thinking, data);
            } else if (currentEvent == 'answer') {
              yield ChatStreamEvent(ChatStreamEventType.answer, data);
            }
            continue;
          }
        }
      }
    } on ApiBusinessException {
      // AI 额度/登录业务错误：透传给调用方（已在上面 rethrow）
      rethrow;
    } on ApiHttpException {
      // HTTP 传输错误：静默结束（调用方看不到也不 Toast，与同步版本传输失败一致）
      return;
    } catch (e) {
      AppDebugLog.wsTransport('history chat stream err=$e');
      return;
    } finally {
      client.close();
    }
  }

  @override
  Future<String?> fetchWidgetFeedingTip() async {
    // tip 已由 home_widget_sync 从留意日缓存派生；此处保留接口兼容、不再拉 HTTP/watch。
    return null;
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
