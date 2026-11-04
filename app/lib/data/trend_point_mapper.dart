import 'history_line_format.dart';
import 'history_mapper.dart';
import 'history_record_metric.dart';
import 'models.dart';

/// 从 rawPayload 读正 expectStartTime（unix 秒）；不可用返回 null（不计准确率）。
int? _expectStartTimeSecFromPayload(Map<String, Object?> p) {
  final v = p['expectStartTime'];
  if (v is int) return v > 0 ? v : null;
  if (v is num) {
    final i = v.toInt();
    return i > 0 ? i : null;
  }
  final parsed = int.tryParse(v?.toString() ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

/// 从 `GET /device/history/api/piece` 单条记录映射为 [TrendPoint]。
/// - `eventNumber == 0`：量为 **持续小时数** `(end - start)` 换算为小时（无效结束为 0）。
/// - 否则：量为 `eventNumber` 的数值（与历史列表计数语义一致）。
/// - 透传 expectStartTime / 实际 start，供近 N 日准确率（不重放）。
TrendPoint? trendPointFromPieceJson(Map<String, dynamic> j) {
  try {
    final rec = historyRecordFromServerMap(j);
    final p = rec.rawPayload;
    // 实际开始：payload startTime，否则 createdAt
    final startAt = parseHistoryInstant(p['startTime']) ?? rec.createdAt;
    final actualSec = historyDateTimeToUnixSeconds(startAt);
    final expectSec = _expectStartTimeSecFromPayload(p);
    return TrendPoint(
      t: rec.createdAt,
      value: historyRecordMetric(rec),
      expectStartTimeSec: expectSec,
      actualStartSec: actualSec > 0 ? actualSec : null,
    );
  } catch (_) {
    return null;
  }
}
