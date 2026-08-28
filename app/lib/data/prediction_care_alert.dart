// 护理留意：服务端日缓存列表的展示 DTO（非医疗诊断）。
// 本地规则引擎已移除；解析见 parseCareAlertEventItems。

import 'event_next_predictor.dart';
import 'models.dart';

/// 护理留意预警类型（排序优先级：间隔拉长 > 进行中过久 > 突然消失 > 其他）。
enum CareAlertType {
  /// 间隔拉长
  elongatedInterval,

  /// 进行中过久
  longActive,

  /// 突然消失
  suddenAbsence,

  /// 服务端未知/扩展类型
  other,
}

/// 类型优先级：数值越小越高。
int careAlertTypePriority(CareAlertType t) {
  switch (t) {
    case CareAlertType.elongatedInterval:
      return 0;
    case CareAlertType.longActive:
      return 1;
    case CareAlertType.suddenAbsence:
      return 2;
    case CareAlertType.other:
      return 3;
  }
}

/// 将 API type 字符串映射为枚举。
CareAlertType careAlertTypeFromApi(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'elongatedInterval':
      return CareAlertType.elongatedInterval;
    case 'longActive':
      return CareAlertType.longActive;
    case 'suddenAbsence':
      return CareAlertType.suddenAbsence;
    default:
      return CareAlertType.other;
  }
}

/// 类型短标签（跑马灯/详情）。
String careAlertTypeLabel(CareAlertType t, {String? raw}) {
  return (raw ?? '').trim();
}

/// 可传路由 extra 的结构化原因（非诊断）。
class CareAlertReason {
  const CareAlertReason({
    required this.type,
    required this.eventId,
    required this.eventName,
    required this.score,
    required this.expectationUsed,
    this.typeRaw,
    this.ageMonths,
    this.medianGap,
    this.lastGap,
    this.expectGapMax,
    this.p75Dur,
    this.elapsed,
    this.expectDurMax,
    this.dailyAvg,
    this.recent48hCount,
    this.stillExpected,
    this.detailLines = const [],
  });

  /// 规范化类型
  final CareAlertType type;

  /// 原始 type 字符串（未知类型展示用）
  final String? typeRaw;

  final String eventId;
  final String eventName;
  // 评分
  final double score;
  final bool expectationUsed;
  final int? ageMonths;
  final Duration? medianGap;
  final Duration? lastGap;
  final Duration? expectGapMax;
  // 75% 持续时间
  final Duration? p75Dur;
  // 已持续时间
  final Duration? elapsed;
  // 期望持续时间最大值
  final Duration? expectDurMax;
  // 日均次数
  final double? dailyAvg;
  // 近 48 小时次数
  final int? recent48hCount;
  final bool? stillExpected;

  /// 服务端可选补充说明行
  final List<String> detailLines;

  /// 展示用类型标签
  String get typeLabel => careAlertTypeLabel(type, raw: typeRaw);

  /// Banner 一行摘要（兼容旧调用）。
  String get bannerSummary => '值得留意 · $eventName：$typeLabel';
}

/// 人类可读时长（详情页）。
String formatCareDuration(Duration? d) {
  if (d == null) return '—';
  var x = d;
  if (x.isNegative) x = Duration.zero;
  if (x.inMinutes < 1) return '不足 1 分钟';
  if (x.inHours < 1) return '${x.inMinutes} 分钟';
  final h = x.inHours;
  final m = x.inMinutes % 60;
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分钟';
}

/// 按事件聚合的留意项（跑马灯一行 / 详情全量原因）。
class CareAlertEventItem {
  const CareAlertEventItem({
    // 服务端当日作用域 UUID
    required this.suggestionId,
    // 事件 ID
    required this.eventId,
    // 事件名称
    required this.eventName,
    // 详情全量原因
    required this.reasons,
    // 跑马灯单行摘要
    required this.summaryLine,
    // 追问时原样传入树洞的提示文案
    this.followUpPrompt = '',
  });

  /// 服务端当日作用域 UUID
  final String suggestionId;

  final String eventId;
  final String eventName;
  final List<CareAlertReason> reasons;

  /// 跑马灯单行摘要
  final String summaryLine;

  /// 追问时原样传入树洞的提示文案
  final String followUpPrompt;

  /// 最佳类型优先级（排序用）
  int get bestTypePriority => reasons.isEmpty
      ? 99
      : reasons
          .map((r) => careAlertTypePriority(r.type))
          .reduce((a, b) => a < b ? a : b);

  /// 同最佳类型下最高分
  double get bestScore {
    if (reasons.isEmpty) return 0;
    final pri = bestTypePriority;
    return reasons
        .where((r) => careAlertTypePriority(r.type) == pri)
        .map((r) => r.score)
        .fold<double>(0, (a, b) => a > b ? a : b);
  }
}

/// 毫秒或数字 → Duration；非法则 null。
Duration? _durationFromMs(Object? v) {
  if (v == null) return null;
  if (v is num) {
    final ms = v.round();
    if (ms < 0) return null;
    return Duration(milliseconds: ms);
  }
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  final ms = int.tryParse(s);
  if (ms == null || ms < 0) return null;
  return Duration(milliseconds: ms);
}

/// 解析单条 reason；失败返回 null。
CareAlertReason? parseCareAlertReason(
  Map<String, dynamic> m, {
  required String eventId,
  required String eventName,
}) {
  final typeRaw = m['type']?.toString();
  final type = careAlertTypeFromApi(typeRaw);
  final scoreRaw = m['score'];
  final score = scoreRaw is num
      ? scoreRaw.toDouble()
      : double.tryParse(scoreRaw?.toString() ?? '') ?? 0.0;
  final detailRaw = m['detailLines'];
  final detailLines = <String>[];
  if (detailRaw is List) {
    for (final e in detailRaw) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) detailLines.add(s);
    }
  }
  return CareAlertReason(
    type: type,
    typeRaw: typeRaw,
    eventId: eventId,
    eventName: eventName,
    score: score,
    expectationUsed: m['expectationUsed'] == true,
    ageMonths: m['ageMonths'] is num ? (m['ageMonths'] as num).toInt() : null,
    medianGap: _durationFromMs(m['medianGapMs']),
    lastGap: _durationFromMs(m['lastGapMs']),
    expectGapMax: _durationFromMs(m['expectGapMaxMs']),
    p75Dur: _durationFromMs(m['p75DurMs']),
    elapsed: _durationFromMs(m['elapsedMs']),
    expectDurMax: _durationFromMs(m['expectDurMaxMs']),
    dailyAvg: m['dailyAvg'] is num ? (m['dailyAvg'] as num).toDouble() : null,
    recent48hCount:
        m['recent48hCount'] is num ? (m['recent48hCount'] as num).toInt() : null,
    stillExpected: m['stillExpected'] is bool ? m['stillExpected'] as bool : null,
    detailLines: detailLines,
  );
}

/// 解析 API `data.items` → 列表；缺 suggestionId/eventId 的项丢弃。
List<CareAlertEventItem> parseCareAlertEventItems(Object? itemsRaw) {
  if (itemsRaw is! List) return const [];
  final out = <CareAlertEventItem>[];
  for (final raw in itemsRaw) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final suggestionId = m['suggestionId']?.toString().trim() ?? '';
    final eventId = m['eventId']?.toString().trim() ?? '';
    if (suggestionId.isEmpty || eventId.isEmpty) continue;
    final eventName = (m['eventName']?.toString().trim().isNotEmpty == true)
        ? m['eventName'].toString().trim()
        : eventId;
    final reasonsRaw = m['reasons'];
    final reasons = <CareAlertReason>[];
    if (reasonsRaw is List) {
      for (final r in reasonsRaw) {
        if (r is! Map) continue;
        final parsed = parseCareAlertReason(
          Map<String, dynamic>.from(r),
          eventId: eventId,
          eventName: eventName,
        );
        if (parsed != null) reasons.add(parsed);
      }
    }
    // 同事件原因：类型优先级升序，再 score 降序
    reasons.sort((a, b) {
      final pc = careAlertTypePriority(a.type)
          .compareTo(careAlertTypePriority(b.type));
      if (pc != 0) return pc;
      return b.score.compareTo(a.score);
    });
    final serverSummary = m['summaryLine']?.toString().trim() ?? '';
    final summaryLine = serverSummary.isNotEmpty
        ? serverSummary
        : (reasons.isEmpty
            ? eventName
            : '$eventName：${reasons.map((r) => r.typeLabel).join('、')}');
    out.add(
      CareAlertEventItem(
        suggestionId: suggestionId,
        eventId: eventId,
        eventName: eventName,
        reasons: reasons,
        summaryLine: summaryLine,
        followUpPrompt: m['followUpPrompt']?.toString() ?? '',
      ),
    );
  }
  // 跨事件排序（服务端未给序时）
  out.sort((a, b) {
    final pc = a.bestTypePriority.compareTo(b.bestTypePriority);
    if (pc != 0) return pc;
    return b.bestScore.compareTo(a.bestScore);
  });
  return out;
}

/// Asia/Shanghai 自然日键 `YYYY-MM-DD`（无夏令时，UTC+8）。
String careAlertShanghaiDayKey([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  final sh = utc.add(const Duration(hours: 8));
  final y = sh.year.toString().padLeft(4, '0');
  final mo = sh.month.toString().padLeft(2, '0');
  final d = sh.day.toString().padLeft(2, '0');
  return '$y-$mo-$d';
}

/// 将任意时刻映射为 Asia/Shanghai 日历日（本地 DateTime，时分归零）。
DateTime careAlertShanghaiCalendarDay(DateTime instant) {
  final sh = instant.toUtc().add(const Duration(hours: 8));
  return DateTime(sh.year, sh.month, sh.day);
}

/// 当前上海自然日的「昨日」日历日。
DateTime careAlertShanghaiYesterdayCalendarDay([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  final sh = utc.add(const Duration(hours: 8));
  final today = DateTime(sh.year, sh.month, sh.day);
  return today.subtract(const Duration(days: 1));
}

/// 7 日 range 内是否至少有一条真历史落在上海「昨日」。
bool rangeHasShanghaiYesterdayOccurrence(
  List<HistoryRecord> records, [
  DateTime? now,
]) {
  if (records.isEmpty) return false;
  final yesterday = careAlertShanghaiYesterdayCalendarDay(now);
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: true);
    if (t == null) continue;
    if (careAlertShanghaiCalendarDay(t) == yesterday) return true;
  }
  return false;
}

/// 由过滤后的留意列表派生小组件 tip：仅非空 summaryLine，多项以空行拼接。
String? deriveWidgetTipTextFromCareAlert(List<CareAlertEventItem> items) {
  if (items.isEmpty) return null;
  final parts = <String>[
    for (final item in items)
      if (item.summaryLine.trim().isNotEmpty) item.summaryLine.trim(),
  ];
  if (parts.isEmpty) return null;
  return parts.join('\n\n');
}
