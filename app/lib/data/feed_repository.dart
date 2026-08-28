import 'history_list_page.dart';
import 'history_post_outcome.dart';
import 'models.dart';

/// 历史 WebSocket 连接阶段，供首页横幅与重连逻辑绑定。
enum HistoryWsPhase {
  ready,
  autoReconnecting,
  gaveUp,
  disconnected,
}

/// 聊天流式事件类型。
enum ChatStreamEventType {
  /// AI 思考过程增量文本。
  thinking,

  /// AI 回答内容增量文本。
  answer,
}

/// 聊天流式事件：包含类型与内容。
class ChatStreamEvent {
  final ChatStreamEventType type;
  final String content;

  const ChatStreamEvent(this.type, this.content);
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

  /// `GET /device/history/api/filter`；失败或无 deviceNo 返回 `null`（不 Toast）。
  /// [listDesc] 为服务端倒序（新→旧）。无 deviceNo **不得** 返回成功空列表。
  Future<List<HistoryRecord>?> tryLoadHistoryFilter({
    int startTime = 0,
    int endTime = 0,
    int limit = kHistoryFilterMaxLimit,
    String eventIds = '',
  });

  /// `GET /device/history/api/v2/list`；失败或无 deviceNo 返回 `null`（不 Toast）。
  Future<HistoryListPage?> tryLoadHistoryPageV2({
    int page = 1,
    int pageSize = kHomeHistoryPageSize,
    int startTime = 0,
    int endTime = 0,
    int limit = 0,
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

  /// `POST /device/history/api/event/add`；成功返回 outcome；传输失败静默。
  Future<HistoryAddPostOutcome> addHistoryEvent(Map<String, dynamic> body);

  /// update POST；业务失败已 Toast。
  Future<HistoryUpdatePostOutcome> postHistoryUpdateBody(Map<String, dynamic> body);

  /// 提交自然语言指令，SSE 流式返回 thinking/answer 事件。
  ///
  /// 调用方订阅 Stream 后，先收到 type=thinking 的事件，
  /// answer 首帧到达后后续事件 type 均为 answer，收到 [DONE] 后流正常结束。
  Stream<ChatStreamEvent> sendCommand(String text);

  /// 小组件 tip 正文；已由 [home_widget_sync] 从留意日缓存派生，保留接口兼容。
  Future<String?> fetchWidgetFeedingTip();
  Stream<SseHistoryPayload> watchLatest();

  /// 在 [watchLatest] 订阅后显式建连；须晚于 gateway HTTP bootstrap 完成。
  void ensureHistoryWebSocketConnected();

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

  /// App 从后台 resume；非 gaveUp 时尝试自动重连（gaveUp 由主壳静默自愈处理）。
  void onAppLifecycleResumed();

  /// 等到历史 WS ready、gaveUp 或超时（供主壳激活后观察是否需静默自愈）。
  Future<({bool ready, HistoryWsPhase phase, String detail})>
      waitForHistoryWsReadyOrTerminal({
    Duration timeout = const Duration(seconds: 25),
  });

  /// 清除本地历史缓存（内存与持久化）。
  Future<void> clearCache();
}
