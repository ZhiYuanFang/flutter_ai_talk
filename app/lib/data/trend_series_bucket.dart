import 'models.dart';
import 'repositories.dart' show TrendRange;

DateTime _dateOnlyLocal(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// 周/月/季：按**本地自然日**分桶，同日多条 **相加**，缺失日 **补 0**；横轴一日一格，不重复日期。
List<TrendPoint> fillTrendBucketsDaily({
  required List<TrendPoint> raw,
  required int startSec,
  required int endSec,
}) {
  final startLocal = DateTime.fromMillisecondsSinceEpoch(startSec * 1000);
  final endLocal = DateTime.fromMillisecondsSinceEpoch(endSec * 1000);
  var day = _dateOnlyLocal(startLocal);
  final endDay = _dateOnlyLocal(endLocal);
  final byDay = <DateTime, double>{};
  for (final p in raw) {
    final k = _dateOnlyLocal(p.t);
    byDay[k] = (byDay[k] ?? 0) + p.value;
  }
  final out = <TrendPoint>[];
  for (; !day.isAfter(endDay); day = day.add(const Duration(days: 1))) {
    out.add(TrendPoint(t: day, value: byDay[day] ?? 0));
  }
  return out;
}

/// 今日：按**本地整点小时**分桶，同小时多条 **相加**，缺失小时 **补 0**；横轴一小时一格。
List<TrendPoint> fillTrendBucketsHourlyToday({
  required List<TrendPoint> raw,
  DateTime? now,
}) {
  final n = (now ?? DateTime.now()).toLocal();
  final dayStart = DateTime(n.year, n.month, n.day);
  final endHour = DateTime(n.year, n.month, n.day, n.hour);
  final byHour = <DateTime, double>{};
  for (final p in raw) {
    final l = p.t.toLocal();
    if (l.isBefore(dayStart) || l.isAfter(n)) continue;
    final k = DateTime(l.year, l.month, l.day, l.hour);
    byHour[k] = (byHour[k] ?? 0) + p.value;
  }
  final out = <TrendPoint>[];
  for (var h = dayStart; !h.isAfter(endHour); h = h.add(const Duration(hours: 1))) {
    out.add(TrendPoint(t: h, value: byHour[h] ?? 0));
  }
  return out;
}

/// 在 [raw] 非空时对齐时间桶并补零；[raw] 为空时返回空列表。
List<TrendPoint> normalizeTrendSeriesForRange(
  List<TrendPoint> raw,
  TrendRange range,
  int startSec,
  int endSec,
) {
  if (raw.isEmpty) return const [];
  switch (range) {
    case TrendRange.today:
      return fillTrendBucketsHourlyToday(raw: raw);
    case TrendRange.week:
    case TrendRange.month:
    case TrendRange.quarter:
      return fillTrendBucketsDaily(raw: raw, startSec: startSec, endSec: endSec);
  }
}
