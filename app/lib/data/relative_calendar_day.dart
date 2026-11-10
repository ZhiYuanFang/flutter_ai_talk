/// 全仓权威相对自然日日词（本地日历日）。
///
/// 词表：前天 / 昨天 / 今天 / 明天 / 后天（相对今天 offset −2…+2）；
/// 更远同年 `M月d日`；跨年 `y年M月d日`。
/// 日+时：`{日词} {HH:mm}`；[omitDayWhenToday] 且今日则仅 `HH:mm`。
library;

/// 本地自然日（时分秒归零）。
DateTime relativeCalendarDateOnly(DateTime t) =>
    DateTime(t.year, t.month, t.day);

/// 相对今天的日词；[day] / [now] 均按本地日历解释。
String formatRelativeCalendarDay(DateTime day, DateTime now) {
  final d = relativeCalendarDateOnly(day.toLocal());
  final t = relativeCalendarDateOnly(now.toLocal());
  final offset = d.difference(t).inDays;
  switch (offset) {
    case -2:
      return '前天';
    case -1:
      return '昨天';
    case 0:
      return '今天';
    case 1:
      return '明天';
    case 2:
      return '后天';
  }
  if (d.year == t.year) return '${d.month}月${d.day}日';
  return '${d.year}年${d.month}月${d.day}日';
}

String _twoDigits(int v) => v.toString().padLeft(2, '0');

/// 日词 + 空格 + `HH:mm`；今日且 [omitDayWhenToday] 时仅时分。
String formatRelativeCalendarDayAndTime(
  DateTime instant,
  DateTime now, {
  bool omitDayWhenToday = false,
}) {
  final local = instant.toLocal();
  final hm = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  final day = relativeCalendarDateOnly(local);
  final today = relativeCalendarDateOnly(now.toLocal());
  if (omitDayWhenToday && day == today) return hm;
  final label = formatRelativeCalendarDay(day, now);
  return '$label $hm';
}
