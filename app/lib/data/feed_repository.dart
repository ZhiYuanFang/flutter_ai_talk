import 'models.dart';

abstract class FeedRepository {
  Future<List<HistoryRecord>> loadHistory();
  /// 成功返回列表（可为空）；失败返回 `null`（不 Toast）。
  Future<List<HistoryRecord>?> tryLoadHistory();
  Future<HistoryRecord?> getRecord(String id);
  /// 成功返回 `true`；业务错误已 Toast 并返回 `false`。
  Future<bool> updateHistoryRecord(
    String id, {
    required String remark,
    DateTime? startTime,
    DateTime? endTime,
    int? usageCount,
    bool clearEndIfNull = false,
  });

  /// `POST /device/history/api/event/delete`，body：`id`、`deviceNo`。成功返回 `true`。
  Future<bool> deleteHistoryRecord(String id);

  /// `POST /device/history/api/event/add`；成功返回 `true`（不消费响应 `id`）。
  Future<bool> addHistoryEvent(Map<String, dynamic> body);
  /// 提交自然语言指令；服务端在 `data.reply` 返回文本回复（可为空）。
  Future<String?> sendCommand(String text);
  Stream<SseHistoryPayload> watchLatest();

  /// 历史 WebSocket 已建链且收到 `auth_ok`（可依赖推送更新列表、允许发聊天）。
  bool get isHistoryWebSocketReady;

  /// 历史 WebSocket 就绪状态（`true` 表示可发聊天）。
  Stream<bool> get historyWsReadyStream;

  /// 断开并重新建立历史 WebSocket。
  Future<void> reconnectHistoryWebSocket();
}
