import 'history_line_format.dart';
import 'history_mapper.dart';
import 'models.dart';

/// 从 `GET /device/history/api/piece` 单条记录映射为 [TrendPoint]。
/// - `eventNumber == 0`：量为 **持续小时数** `(end - start)` 换算为小时（无效结束为 0）。
/// - 否则：量为 `eventNumber` 的数值（与历史列表计数语义一致）。
TrendPoint? trendPointFromPieceJson(Map<String, dynamic> j) {
  try {
    final rec = historyRecordFromServerMap(j);
    final p = rec.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final double metric;
    if (n == 0) {
      final start = parseHistoryInstant(p['startTime']);
      final end = parseHistoryInstant(p['endTime']);
      if (start == null || end == null || end.isBefore(start)) {
        metric = 0;
      } else {
        metric = end.difference(start).inSeconds / 3600.0;
      }
    } else {
      final numVal = p['eventNumber'];
      metric = (numVal is num) ? numVal.toDouble() : double.tryParse(numVal?.toString() ?? '') ?? 0;
    }
    return TrendPoint(t: rec.createdAt, value: metric);
  } catch (_) {
    return null;
  }
}
