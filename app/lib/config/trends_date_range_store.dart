import 'package:shared_preferences/shared_preferences.dart';

/// 趋势中心起止日期（本地自然日，不含时分）。
class TrendsDateRange {
  const TrendsDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// 趋势范围预设（含首尾自然日天数）。
enum TrendsRangePreset {
  days7(7, '近7日'),
  days15(15, '近15日'),
  days30(30, '近1个月');

  const TrendsRangePreset(this.dayCount, this.label);

  final int dayCount;
  final String label;
}

/// 趋势日期范围：校验、默认、预设推导。
class TrendsDateRangeLogic {
  TrendsDateRangeLogic._();

  static const maxInclusiveDays = 30;

  static DateTime dateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static int inclusiveCalendarDays(DateTime start, DateTime end) =>
      end.difference(start).inDays + 1;

  static bool isValidSpan(DateTime start, DateTime end) {
    if (end.isBefore(start)) return false;
    return inclusiveCalendarDays(start, end) <= maxInclusiveDays;
  }

  /// 由预设推导：结束日=今日，开始日=今日往前 n−1 天。
  static TrendsDateRange rangeForPreset(
    TrendsRangePreset preset, [
    DateTime? now,
  ]) {
    final today = dateOnly(now ?? DateTime.now());
    final start = today.subtract(Duration(days: preset.dayCount - 1));
    return TrendsDateRange(start: start, end: today);
  }

  /// 默认近7日（不再使用「本周一至今天」）。
  static TrendsDateRange defaultRange([DateTime? now]) =>
      rangeForPreset(TrendsRangePreset.days7, now);

  static TrendsDateRange clampEndToToday(TrendsDateRange range) {
    final today = dateOnly(DateTime.now());
    var end = dateOnly(range.end);
    if (end.isAfter(today)) end = today;
    var start = dateOnly(range.start);
    if (start.isAfter(end)) start = end;
    return TrendsDateRange(start: start, end: end);
  }

  static (int startSec, int endSec) toUnixBounds(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return (s.millisecondsSinceEpoch ~/ 1000, e.millisecondsSinceEpoch ~/ 1000);
  }

  static bool isSameDay(DateTime a, DateTime b) => dateOnly(a) == dateOnly(b);

  static bool dayInRange(DateTime day, DateTime start, DateTime end) {
    final d = dateOnly(day);
    return !d.isBefore(dateOnly(start)) && !d.isAfter(dateOnly(end));
  }
}

/// 旧版范围持久化（趋势页已不再读写；保留以免其它残留引用编译失败）。
class TrendsDateRangeStore {
  static const _startKey = 'trends_range_start_v1';
  static const _endKey = 'trends_range_end_v1';

  static String _fmt(DateTime d) {
    final x = TrendsDateRangeLogic.dateOnly(d);
    return '${x.year.toString().padLeft(4, '0')}-'
        '${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (y == null || m == null || day == null) return null;
    return DateTime(y, m, day);
  }

  static Future<void> save(TrendsDateRange range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startKey, _fmt(range.start));
    await prefs.setString(_endKey, _fmt(range.end));
  }

  /// 读取并校验；非法或超 30 天返回 null。
  static Future<TrendsDateRange?> loadValid() async {
    final prefs = await SharedPreferences.getInstance();
    final start = _parse(prefs.getString(_startKey));
    final end = _parse(prefs.getString(_endKey));
    if (start == null || end == null) return null;
    final clamped = TrendsDateRangeLogic.clampEndToToday(
      TrendsDateRange(start: start, end: end),
    );
    if (!TrendsDateRangeLogic.isValidSpan(clamped.start, clamped.end)) {
      return null;
    }
    return clamped;
  }
}
