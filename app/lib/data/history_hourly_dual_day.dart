import 'event_branding.dart';
import 'history_line_format.dart';
import 'history_mapper.dart';
import 'history_record_metric.dart';
import 'models.dart';
import 'trend_series_bucket.dart';

/// 今/昨各 24 整点桶的小时趋势序列。
class HourlyDualDaySeries {
  const HourlyDualDaySeries({
    required this.today,
    required this.yesterday,
  });

  final List<TrendPoint> today;
  final List<TrendPoint> yesterday;

  static HourlyDualDaySeries empty([DateTime? now]) {
    final n = (now ?? DateTime.now()).toLocal();
    final today = DateTime(n.year, n.month, n.day);
    final yesterday = today.subtract(const Duration(days: 1));
    return HourlyDualDaySeries(
      today: fillTrendBucketsHourlyFullDay(raw: const [], dayLocal: today),
      yesterday: fillTrendBucketsHourlyFullDay(raw: const [], dayLocal: yesterday),
    );
  }
}

bool historyRecordMatchesEventKey(HistoryRecord record, String eventKey) {
  final id = historyRecordEventId(record);
  final key = id.isNotEmpty ? id : record.eventName.trim();
  return key == eventKey;
}

List<TrendPoint> _historyRecordsToTrendPoints(
  List<HistoryRecord> items,
  String eventKey,
) {
  final pts = <TrendPoint>[];
  for (final r in items) {
    if (!historyRecordMatchesEventKey(r, eventKey)) continue;
    if (!countsTowardTodayTotal(r)) continue;
    final p = r.rawPayload;
    final t = parseHistoryInstant(p['startTime']) ?? r.createdAt;
    pts.add(TrendPoint(t: t.toLocal(), value: historyRecordMetric(r)));
  }
  return pts;
}

List<TrendPoint> _trendPointsForLocalDay(
  List<TrendPoint> raw,
  DateTime dayLocal,
) {
  final day = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
  final next = day.add(const Duration(days: 1));
  final filtered = raw.where((p) {
    final l = p.t.toLocal();
    return !l.isBefore(day) && l.isBefore(next);
  }).toList();
  return fillTrendBucketsHourlyFullDay(raw: filtered, dayLocal: day);
}

/// 从本地历史列表聚合今/昨各 24 桶（排除未结束计时）。
HourlyDualDaySeries aggregateHourlyDualDayFromHistory(
  List<HistoryRecord> items,
  String eventKey, [
  DateTime? now,
]) {
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final raw = _historyRecordsToTrendPoints(items, eventKey);
  return HourlyDualDaySeries(
    today: _trendPointsForLocalDay(raw, today),
    yesterday: _trendPointsForLocalDay(raw, yesterday),
  );
}

/// piece 原始列表 → 过滤后分日 24 桶。
HourlyDualDaySeries hourlyDualDayFromPieceRecords(
  List<Map<String, dynamic>> pieceRows,
  String eventKey, [
  DateTime? now,
]) {
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final pts = <TrendPoint>[];
  for (final row in pieceRows) {
    HistoryRecord rec;
    try {
      rec = historyRecordFromServerMap(row);
    } catch (_) {
      continue;
    }
    if (!historyRecordMatchesEventKey(rec, eventKey)) continue;
    if (!countsTowardTodayTotal(rec)) continue;
    final p = rec.rawPayload;
    final t = parseHistoryInstant(p['startTime']) ?? rec.createdAt;
    pts.add(TrendPoint(t: t.toLocal(), value: historyRecordMetric(rec)));
  }
  return HourlyDualDaySeries(
    today: _trendPointsForLocalDay(pts, today),
    yesterday: _trendPointsForLocalDay(pts, yesterday),
  );
}

/// 昨日 0:00 – 今日 23:59:59 本地（Unix 秒）。
(int startSec, int endSec) hourlyDualDayPieceBounds([DateTime? now]) {
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final startSec = yesterday.millisecondsSinceEpoch ~/ 1000;
  final endSec = DateTime(today.year, today.month, today.day, 23, 59, 59)
          .millisecondsSinceEpoch ~/
      1000;
  return (startSec, endSec);
}
