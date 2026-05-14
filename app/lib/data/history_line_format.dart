import 'package:flutter/material.dart';

import 'models.dart';

int historyPayloadInt(Map<String, Object?> p, String key) {
  final v = p[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// 网关缺失 / `0` / 空串 / Unix 起点视为「未设置」。
bool historyInstantUnset(DateTime? t) {
  if (t == null) return true;
  return t.millisecondsSinceEpoch == 0;
}

/// 解析 `startTime` / `endTime`；未设置返回 `null`。
DateTime? parseHistoryInstant(Object? raw) {
  if (raw == null) return null;
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == '0') return null;
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    final d = DateTime.tryParse(normalized);
    return d == null || historyInstantUnset(d) ? null : d.toLocal();
  }
  if (raw is int) {
    if (raw == 0) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true).toLocal();
    return historyInstantUnset(d) ? null : d;
  }
  if (raw is num) {
    final i = raw.toInt();
    if (i == 0) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(i * 1000, isUtc: true).toLocal();
    return historyInstantUnset(d) ? null : d;
  }
  return null;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// 相对「当前」的列表用时间短串（本地自然日 / 年）。
String formatHistoryInstant(DateTime t, DateTime nowLocal) {
  final a = DateTime(t.year, t.month, t.day);
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final yest = today.subtract(const Duration(days: 1));
  final hm = '${_two(t.hour)}:${_two(t.minute)}';

  if (a == today) return hm;
  if (a == yest) return '昨天$hm';
  if (t.year == nowLocal.year) return '${t.month}月${t.day}日 $hm';
  return '${t.year}年${t.month}月${t.day}日 $hm';
}

/// `eventNumber == 0` 且已结束时的用时文案；不满 1 分钟（含 0 分钟）为「不足 1 分钟」。
String formatDurationForEvent0(DateTime start, DateTime end) {
  var diff = end.difference(start);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 60) return '不足 1 分钟';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟';
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  return '$h小时$m分钟';
}

String _displayEventName(String eventName) {
  final e = eventName.trim();
  return e.isEmpty ? '未知事件' : e;
}

/// 无样式、用于语义化字符串或调试（与 Rich 规则一致）。
String historyLinePlainText(HistoryRecord record, DateTime nowLocal) {
  final p = record.rawPayload;
  final n = historyPayloadInt(p, 'eventNumber');
  final remark = (p['remark'] as String? ?? '').trim();
  final end = parseHistoryInstant(p['endTime']);
  final start = parseHistoryInstant(p['startTime']);
  final endUnset = historyInstantUnset(end);
  final name = _displayEventName(record.eventName);

  if (n == 1) {
    final t = formatHistoryInstant(end ?? record.createdAt, nowLocal);
    return remark.isEmpty ? '$t:$name' : '$t:$name($remark)';
  }
  if (n > 1) {
    final t = formatHistoryInstant(end ?? record.createdAt, nowLocal);
    return '$t:$name->$n';
  }
  if (n == 0 && endUnset) {
    final st = start ?? record.createdAt;
    final t = formatHistoryInstant(st, nowLocal);
    return '$t:$name -> 开始计时';
  }
  if (n == 0 && !endUnset && end != null) {
    final st = start ?? record.createdAt;
    final te = formatHistoryInstant(end, nowLocal);
    final dur = formatDurationForEvent0(st, end);
    return '$te:$name-> 用时$dur';
  }
  return formatHistoryLine(record.eventName, record.action);
}

TextStyle _eventNameStyle(TextStyle base) {
  final fs = base.fontSize ?? 14;
  return base.copyWith(fontWeight: FontWeight.w600, fontSize: fs * 1.08);
}

TextStyle _remarkStyle(TextStyle base) {
  final fs = base.fontSize ?? 14;
  return base.copyWith(fontWeight: FontWeight.normal, fontSize: fs * 0.85, color: base.color?.withValues(alpha: 0.85));
}

/// 首页历史行 Rich 片段；[base] 为整行默认样式（含字号）。
List<InlineSpan> historyLineSpans(HistoryRecord record, TextStyle base, [DateTime? now]) {
  final nowLocal = (now ?? DateTime.now()).toLocal();
  final p = record.rawPayload;
  final n = historyPayloadInt(p, 'eventNumber');
  final remark = (p['remark'] as String? ?? '').trim();
  final end = parseHistoryInstant(p['endTime']);
  final start = parseHistoryInstant(p['startTime']);
  final endUnset = historyInstantUnset(end);
  final name = _displayEventName(record.eventName);
  final ev = _eventNameStyle(base);
  final rm = _remarkStyle(base);

  if (n == 1) {
    final t = formatHistoryInstant(end ?? record.createdAt, nowLocal);
    if (remark.isEmpty) {
      return [TextSpan(text: '$t:', style: base), TextSpan(text: name, style: ev)];
    }
    return [
      TextSpan(text: '$t:', style: base),
      TextSpan(text: name, style: ev),
      TextSpan(text: '(', style: base),
      TextSpan(text: remark, style: rm),
      TextSpan(text: ')', style: base),
    ];
  }
  if (n > 1) {
    final t = formatHistoryInstant(end ?? record.createdAt, nowLocal);
    return [
      TextSpan(text: '$t:', style: base),
      TextSpan(text: name, style: ev),
      TextSpan(text: '->$n', style: base),
    ];
  }
  if (n == 0 && endUnset) {
    final st = start ?? record.createdAt;
    final t = formatHistoryInstant(st, nowLocal);
    return [
      TextSpan(text: '$t:', style: base),
      TextSpan(text: name, style: ev),
      TextSpan(text: ' -> 开始计时', style: base),
    ];
  }
  if (n == 0 && !endUnset && end != null) {
    final st = start ?? record.createdAt;
    final te = formatHistoryInstant(end, nowLocal);
    final dur = formatDurationForEvent0(st, end);
    return [
      TextSpan(text: '$te:', style: base),
      TextSpan(text: name, style: ev),
      TextSpan(text: '-> 用时', style: base),
      TextSpan(text: dur, style: base),
    ];
  }
  return [TextSpan(text: formatHistoryLine(record.eventName, record.action), style: base)];
}
