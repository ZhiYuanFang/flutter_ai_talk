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

/// 网格倒计时：`H:MM:SS`（小时可超过 24；分秒两位补零）。
/// [overdue] 为真时固定 `00:00:00`（停表）。
String formatPredictionCountdownHms(DateTime nextAt, DateTime now,
    {required bool overdue}) {
  if (overdue) return '00:00:00';
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
    var d = now.difference(nextAt);
    if (d.isNegative) d = Duration.zero;
    if (d.inMinutes < 1) return '超时 1 分钟';
    if (d.inMinutes < 60) return '超时 ${d.inMinutes} 分钟';
    if (d.inHours < 24) return '超时 ${d.inHours} 小时';
    return '超时 ${d.inDays} 天';
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

/// 预测卡片：「上一次{事件名}：{时间}」。
String formatPredictionLastOccurrenceLabel(
  String eventName,
  DateTime? lastAt,
  DateTime now,
) {
  final name = eventName.trim().isEmpty ? '未知事件' : eventName.trim();
  return '上一次$name：${formatWidgetLastAt(lastAt, now)}';
}

/// 上次记录时间（native 与 App 预览对齐）。
String formatWidgetLastAt(DateTime? lastAt, DateTime now) {
  if (lastAt == null) return '暂无';
  final local = lastAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  if (day == today) return '$h:$m';
  if (day == today.subtract(const Duration(days: 1))) return '昨天 $h:$m';
  return '${local.month}月${local.day}日';
}
