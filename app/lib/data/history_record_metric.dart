import 'package:flutter/foundation.dart';

import 'event_branding.dart';
import 'history_line_format.dart';
import 'models.dart';

/// 单条历史记录的统计量（与趋势 [trend_point_mapper] 一致）。
double historyRecordMetric(HistoryRecord record) {
  final p = record.rawPayload;
  final n = historyPayloadInt(p, 'eventNumber');
  if (n == 0) {
    final start = parseHistoryInstant(p['startTime']);
    final end = parseHistoryInstant(p['endTime']);
    if (start == null || end == null || end.isBefore(start)) {
      return 0;
    }
    return end.difference(start).inSeconds / 3600.0;
  }
  final numVal = p['eventNumber'];
  return (numVal is num) ? numVal.toDouble() : double.tryParse(numVal?.toString() ?? '') ?? 0;
}

bool isHistoryRecordOnLocalDay(HistoryRecord record, DateTime dayLocal) {
  final t = record.createdAt.toLocal();
  final d = DateTime(t.year, t.month, t.day);
  final k = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
  return d == k;
}

/// 是否计入今日汇总（未结束的计时不累加）。
bool countsTowardTodayTotal(HistoryRecord record) {
  final p = record.rawPayload;
  final n = historyPayloadInt(p, 'eventNumber');
  if (n == 0) {
    final end = parseHistoryInstant(p['endTime']);
    if (historyInstantUnset(end)) return false;
  }
  return historyRecordMetric(record) > 0;
}

@immutable
class TodayEventTotal {
  const TodayEventTotal({
    required this.eventId,
    required this.eventName,
    required this.value,
    required this.isDurationHours,
    required this.unit,
  });

  final String eventId;
  final String eventName;
  final double value;
  final bool isDurationHours;
  final String unit;
}

/// 从当前历史列表聚合「今日」各事件总额（本地自然日，与列表/WS 同步）。
List<TodayEventTotal> aggregateTodayTotals(
  List<HistoryRecord> items, [
  DateTime? now,
]) {
  final nowLocal = (now ?? DateTime.now()).toLocal();
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final sums = <String, ({String eventName, double value, bool isDurationHours, String unit})>{};

  for (final r in items) {
    if (!isHistoryRecordOnLocalDay(r, today)) continue;
    if (!countsTowardTodayTotal(r)) continue;
    final eventId = historyRecordEventId(r);
    final key = eventId.isNotEmpty ? eventId : r.eventName.trim();
    if (key.isEmpty) continue;
    final name = r.eventName.trim().isEmpty ? '未知事件' : r.eventName.trim();
    final metric = historyRecordMetric(r);
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    final isDur = n == 0;
    final unit = (p['eventUnit'] as String?)?.trim() ?? '';
    final prev = sums[key];
    if (prev == null) {
      sums[key] = (eventName: name, value: metric, isDurationHours: isDur, unit: unit);
    } else {
      sums[key] = (
        eventName: prev.eventName,
        value: prev.value + metric,
        isDurationHours: prev.isDurationHours || isDur,
        unit: prev.unit.isNotEmpty ? prev.unit : unit,
      );
    }
  }

  final out = sums.entries
      .map(
        (e) => TodayEventTotal(
          eventId: e.key,
          eventName: e.value.eventName,
          value: e.value.value,
          isDurationHours: e.value.isDurationHours,
          unit: e.value.unit,
        ),
      )
      .toList();
  out.sort((a, b) => a.eventName.compareTo(b.eventName));
  return out;
}

String formatTodayTotalAmount(TodayEventTotal t) {
  if (t.isDurationHours) {
    if (t.value < 1 / 60) return '不足1分钟';
    if (t.value < 1) {
      final mins = (t.value * 60).round();
      return mins < 1 ? '不足1分钟' : '$mins分钟';
    }
    final h = t.value.floor();
    final m = ((t.value - h) * 60).round();
    if (m == 0) return '$h小时';
    return '$h小时$m分钟';
  }
  if (t.value == t.value.roundToDouble()) {
    return '${t.value.toInt()}';
  }
  final s = t.value.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String formatTodayTotalChipLabel(TodayEventTotal t) {
  final amount = formatTodayTotalAmount(t);
  final unit = t.unit.trim();
  if (t.isDurationHours) {
    return '${t.eventName} $amount';
  }
  if (unit.isEmpty) {
    return '${t.eventName} $amount';
  }
  return '${t.eventName} $amount$unit';
}
