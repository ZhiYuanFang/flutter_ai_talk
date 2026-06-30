import 'history_list_page.dart';
import 'models.dart';

/// 历史 WebSocket 连接阶段，供首页横幅与重连逻辑绑定。
enum HistoryWsPhase {
  ready,
  autoReconnecting,
  gaveUp,
  disconnected,
}

abstract class FeedRepository {
  Future<List<HistoryRecord>> loadHistory();
  /// 成功返回列表（可为空）；失败返回 `null`（不 Toast）。
  Future<List<HistoryRecord>?> tryLoadHistory();
  /// 分页拉取；失败返回 `null`（不 Toast）。
  Future<HistoryListPage?> tryLoadHistoryPage({
    required int page,
    int pageSize = kHomeHistoryPageSize,
  });
  Future<HistoryRecord?> getRecord(String id);
  /// 成功返回 `true`；业务错误已 Toast 并返回 `false`。
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
  });

  /// `POST /device/history/api/event/delete`，body：`id`、`deviceNo`。成功返回 `true`。
  Future<bool> deleteHistoryRecord(String id);

  /// `POST /device/history/api/event/add`；成功返回 `data.id` 字符串，失败返回 `null`（已 Toast）。
  Future<String?> addHistoryEvent(Map<String, dynamic> body);
  /// 提交自然语言指令；服务端在 `data.reply` 返回文本回复（可为空）。
  Future<String?> sendCommand(String text);
  Stream<SseHistoryPayload> watchLatest();

  /// 历史 WebSocket 已鉴权且完成首次 JSON ping/pong（可发聊天、依赖推送增量）。
  bool get isHistoryWebSocketReady;

  /// 历史 WebSocket 就绪状态（`true` 表示可发聊天）。
  Stream<bool> get historyWsReadyStream;

  /// 历史 WebSocket 阶段流（`ready` / `autoReconnecting` / `gaveUp` / `disconnected`）。
  Stream<HistoryWsPhase> get historyWsPhaseStream;

  /// 当前历史 WebSocket 阶段。
  HistoryWsPhase get historyWsPhase;

  /// 将 3-strike 计数清零并退出 gave-up（login / deviceNo 变更 / 横幅手动重连前调用）。
  void resetHistoryWebSocketStrike();

  /// 断开并重新建立历史 WebSocket；[resetStrike] 为 true 时先清零 strike 并退出 gave-up。
  Future<void> reconnectHistoryWebSocket({bool resetStrike = false});

  /// 登出或 tearDown：关闭订阅与连接，不发起新 connect。
  void disconnectHistoryWebSocket();

  /// App 从后台 resume；gave-up 态下不得自动重连。
  void onAppLifecycleResumed();

  /// 清除本地历史缓存（内存与持久化）。
  Future<void> clearCache();
}
