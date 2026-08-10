import 'models.dart';

/// 主页历史列表每页条数（与 `GET /device/history/api/list` 一致）。
const kHomeHistoryPageSize = 20;

/// `GET /device/history/api/filter` 的 limit 上限（与 go_ai_talk 一致）。
const kHistoryFilterMaxLimit = 500;

/// 历史列表 API 单页结果（`list` 为服务端倒序：新→旧）。
class HistoryListPage {
  const HistoryListPage({
    required this.listDesc,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<HistoryRecord> listDesc;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;
}
