import 'history_mapper.dart';
import 'history_record_metric.dart';
import 'models.dart';

/// 从 `GET /device/history/api/piece` 单条记录映射为 [TrendPoint]。
/// - `eventNumber == 0`：量为 **持续小时数** `(end - start)` 换算为小时（无效结束为 0）。
/// - 否则：量为 `eventNumber` 的数值（与历史列表计数语义一致）。
TrendPoint? trendPointFromPieceJson(Map<String, dynamic> j) {
  try {
    final rec = historyRecordFromServerMap(j);
    return TrendPoint(t: rec.createdAt, value: historyRecordMetric(rec));
  } catch (_) {
    return null;
  }
}
