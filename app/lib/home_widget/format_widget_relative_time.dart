import '../data/relative_calendar_day.dart';

/// 进行中计时 elapsed（与 [formatActiveTimerElapsed] 语义对齐的纯 Duration 版）。
String formatWidgetActiveElapsed(Duration elapsed) {
  var d = elapsed;
  if (d.isNegative) d = Duration.zero;
  if (d.inHours < 1) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String formatWidgetOverdue(Duration overdueBy) {
  var d = overdueBy;
  if (d.isNegative) d = Duration.zero;
  if (d.inMinutes < 1) return '已超时 · 约 1 分钟';
  if (d.inMinutes < 60) return '已超时 · 约 ${d.inMinutes} 分钟';
  if (d.inHours < 24) return '已超时 · 约 ${d.inHours} 小时';
  return '已超时 · 约 ${d.inDays} 天';
}

String formatWidgetUpcoming(Duration until) {
  var d = until;
  if (d.isNegative) d = Duration.zero;
  if (d.inMinutes < 1) return '约 1 分钟后';
  if (d.inMinutes < 60) return '约 ${d.inMinutes} 分钟后';
  if (d.inHours < 24) return '约 ${d.inHours} 小时后';
  return '约 ${d.inDays} 天后';
}

String formatWidgetPredictSubtitle(DateTime nextAt, DateTime now, {required bool overdue}) {
  if (overdue) {
    return formatWidgetOverdue(now.difference(nextAt));
  }
  return formatWidgetUpcoming(nextAt.difference(now));
}

/// 远距改显预估时刻的阈值（严格大于）。
const kPredictionFarCountdownThreshold = Duration(minutes: 10);

/// 预估时刻拆分：日期前缀可空（今天无前缀、不加「今天」）。
class PredictionEstimatedClockParts {
  const PredictionEstimatedClockParts({this.datePrefix, required this.hm});

  final String? datePrefix;
  final String hm;

  /// 单行拼接（无 UI 字号区分时用）。
  String get combined =>
      datePrefix == null ? hm : '$datePrefix $hm';
}

/// 预估 `nextAt` 本地钟点 parts（日前缀走权威相对自然日核；今日无前缀）。
PredictionEstimatedClockParts predictionEstimatedClockParts(
  DateTime nextAt,
  DateTime now,
) {
  final local = nextAt.toLocal();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final today = relativeCalendarDateOnly(now.toLocal());
  final day = relativeCalendarDateOnly(local);
  if (day == today) {
    return PredictionEstimatedClockParts(hm: hm);
  }
  return PredictionEstimatedClockParts(
    datePrefix: formatRelativeCalendarDay(day, now),
    hm: hm,
  );
}

/// 逾期大数字 / 兼容：预估 `nextAt` 本地钟点串。
String formatPredictionEstimatedClock(DateTime nextAt, DateTime now) {
  return predictionEstimatedClockParts(nextAt, now).combined;
}

/// 是否进入「只显示预估时刻」态：逾期，或剩余严格大于 10 分钟。
bool predictionShowsEstimatedClock(
  DateTime nextAt,
  DateTime now, {
  required bool overdue,
}) {
  if (overdue) return true;
  return nextAt.difference(now) > kPredictionFarCountdownThreshold;
}

/// 网格倒计时：短距 `H:MM:SS`；时刻态（逾期或 &gt;10m）为预估本地时刻串。
String formatPredictionCountdownHms(DateTime nextAt, DateTime now,
    {required bool overdue}) {
  if (predictionShowsEstimatedClock(nextAt, now, overdue: overdue)) {
    return formatPredictionEstimatedClock(nextAt, now);
  }
  var d = nextAt.difference(now);
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${h.toString().padLeft(2, '0')}:$m:$s';
}

/// 网格卡片短相对时间：`超时 x 分钟` / `x 小时后`（无「下次」）。
String formatPredictionGridRelative(DateTime nextAt, DateTime now,
    {required bool overdue}) {
  if (overdue) {
    // var d = now.difference(nextAt);
    // if (d.isNegative) d = Duration.zero;
    // if (d.inMinutes < 1) return '超时 1 分钟';
    // if (d.inMinutes < 60) return '超时 ${d.inMinutes} 分钟';
    // if (d.inHours < 24) return '超时 ${d.inHours} 小时';
    // return '超时 ${d.inDays} 天';
    return '已超时';
  }
  var d = nextAt.difference(now);
  if (d.isNegative) d = Duration.zero;
  if (d.inMinutes < 1) return '1 分钟后';
  if (d.inMinutes < 60) return '${d.inMinutes} 分钟后';
  if (d.inHours < 24) return '${d.inHours} 小时后';
  return '${d.inDays} 天后';
}

String formatWidgetActiveSubtitle(DateTime startAt, DateTime now) {
  return '进行中 · ${formatWidgetActiveElapsed(now.difference(startAt))}';
}

/// 预测卡片上次行文案。
///
/// [includeEventNamePrefix] 为真：`上一次{事件名}：{时间}[ · 备注]`（非预约）。
/// 为假：`{时间}[ · 备注]`（预约，省横向前缀）。
String formatPredictionLastOccurrenceLabel(
  String eventName,
  DateTime? lastAt,
  DateTime now, {
  String remark = '',
  bool includeEventNamePrefix = true,
}) {
  final time = formatWidgetLastAt(lastAt, now);
  final String base;
  if (includeEventNamePrefix) {
    final name = eventName.trim().isEmpty ? '未知事件' : eventName.trim();
    base = '上一次$name：$time';
  } else {
    base = time;
  }
  final rm = remark.trim();
  if (rm.isEmpty) return base;
  return '$base · $rm';
}

/// 上次记录时间（native 与 App 预览对齐）；今日仅时分，跨日为「日词 HH:mm」。
String formatWidgetLastAt(DateTime? lastAt, DateTime now) {
  if (lastAt == null) return '暂无';
  return formatRelativeCalendarDayAndTime(
    lastAt,
    now,
    omitDayWhenToday: true,
  );
}
