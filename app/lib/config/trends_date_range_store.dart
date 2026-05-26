import 'package:shared_preferences/shared_preferences.dart';

/// 趋势中心起止日期（本地自然日，不含时分）。
class TrendsDateRange {
  const TrendsDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// 趋势日期范围：校验、默认、持久化。
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

  static DateTime mondayOfWeek(DateTime ref) {
    final d = dateOnly(ref);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static TrendsDateRange defaultRange() {
    final today = dateOnly(DateTime.now());
    return TrendsDateRange(start: mondayOfWeek(today), end: today);
  }

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

  static bool isSameDay(DateTime a, DateTime b) =>
      dateOnly(a) == dateOnly(b);
}

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
