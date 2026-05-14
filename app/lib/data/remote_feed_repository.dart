import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import 'history_mapper.dart';
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

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  var _wsReady = false;

  void _toast(String m) {
    _ref.read(apiToastProvider.notifier).state = m;
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

  void _tearDownWs() {
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    _emitWsReady(false);
  }

  void _ensureWs() {
    if (_wsUrl.isEmpty) {
      _emitWsReady(false);
      return;
    }
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _emitWsReady(false);
      return;
    }
    if (_ws != null) return;
    _openSocket();
  }

  void _openSocket() {
    if (_wsUrl.isEmpty) {
      _emitWsReady(false);
      return;
    }
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      _emitWsReady(false);
      return;
    }
    final token = _ref.read(sessionProvider).accessToken;
    if (token == null || token.isEmpty) {
      _emitWsReady(false);
      return;
    }
    _tearDownWs();
    try {
      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _wsSub = _ws!.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String);
            if (decoded is! Map<String, dynamic>) return;
            final type = decoded['type'] as String?;
            if (type == 'error') {
              _toast(decoded['message'] as String? ?? '连接异常');
              return;
            }
            if (type == 'auth_ok') {
              _emitWsReady(true);
              return;
            }
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
        },
        onError: (_) {
          _tearDownWs();
        },
        onDone: () {
          _tearDownWs();
        },
        cancelOnError: true,
      );
      final first = jsonEncode({
        'type': 'auth',
        'accessToken': token,
        'deviceNo': dn,
      });
      _ws!.sink.add(first);
    } catch (_) {
      _ws = null;
      _emitWsReady(false);
      _toast('历史 WebSocket 连接失败，请点击重连');
    }
  }

  @override
  Future<void> reconnectHistoryWebSocket() async {
    _tearDownWs();
    _openSocket();
  }

  @override
  Future<List<HistoryRecord>> loadHistory() async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      return [];
    }
    try {
      final data = await _api.getEnvelope(
        '/device/history/api/list',
        query: {'deviceNo': dn, 'page': '1', 'pageSize': '50'},
      );
      if (data == null) return [];
      final list = data['list'] as List<dynamic>? ?? const [];
      final out = <HistoryRecord>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          out.add(historyRecordFromServerMap(e));
        }
      }
      _cache
        ..clear()
        ..addAll(out);
      return List<HistoryRecord>.from(_cache);
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return [];
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
  }) async {
    final existing = await getRecord(id);
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
    _ensureWs();
    return _controller.stream;
  }

  void dispose() {
    _tearDownWs();
    if (!_wsReadyController.isClosed) {
      _wsReadyController.close();
    }
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
