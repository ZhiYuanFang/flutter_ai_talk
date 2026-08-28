import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import 'home_widget_payload.dart';

const kWidgetTipDayKey = 'widget_tip_day_v1';
const kWidgetTipTextKey = 'widget_tip_text_v1';
/// 未截断全文，供陪伴注入；桌面仍用 [kWidgetTipTextKey] trim 版。
const kWidgetTipFullTextKey = 'widget_tip_full_text_v1';
/// 已废弃：fail-day 熔断已移除；清理时仍 remove 以迁移旧安装。
const kWidgetTipFailDayKey = 'widget_tip_fail_day_v1';
/// 已注入陪伴的自然日 yyyy-MM-dd；清理陪伴记录不得清除此键。
const kWidgetTipInjectedDayKey = 'widget_tip_injected_day_v1';

const _kMaxTipLines = 5;
const _kMaxTipChars = 160;

/// 从 prefs 读取已缓存 tip（供 sync 在留意未 ready 时复用推送）。
Future<HomeWidgetTipPayload?> loadWidgetTipSnapshotFromPrefs({
  required DateTime now,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = prefs.getString(kWidgetTipTextKey)?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return HomeWidgetTipPayload(text: trimmed, fetchedAt: now);
}

/// 将派生 tip 正文写入 prefs；[clearWhenEmpty] 为 false 且正文空时保留原缓存。
Future<HomeWidgetTipPayload?> persistWidgetTipSnapshot({
  required String? derivedText,
  required DateTime now,
  bool clearWhenEmpty = true,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final dayKey = _dayKey(now);
  // 迁移：移除旧 fail-day 锁死键
  await prefs.remove(kWidgetTipFailDayKey);

  final full = derivedText?.trim() ?? '';
  if (full.isEmpty) {
    if (!clearWhenEmpty) {
      return loadWidgetTipSnapshotFromPrefs(now: now);
    }
    await prefs.remove(kWidgetTipDayKey);
    await prefs.remove(kWidgetTipTextKey);
    await prefs.remove(kWidgetTipFullTextKey);
    return null;
  }
  final trimmed = _trimTipText(full);
  await prefs.setString(kWidgetTipDayKey, dayKey);
  await prefs.setString(kWidgetTipTextKey, trimmed);
  await prefs.setString(kWidgetTipFullTextKey, full);
  AppDebugLog.homeWidget(
    'tip refreshed day=$dayKey trimLen=${trimmed.length} fullLen=${full.length}',
  );
  return HomeWidgetTipPayload(text: trimmed, fetchedAt: now);
}

/// 预测页/展示用：有 tip 正文则返回；与小组件对齐，不校验当日 dayKey。
Future<String?> peekWidgetTipDisplayText({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = prefs.getString(kWidgetTipTextKey)?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// 陪伴可注入文案：当日有缓存且未注入时，优先全文，回退 trim。
Future<String?> peekWidgetTipInjectText({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final dayKey = _dayKey(now ?? DateTime.now());
  final cachedDay = prefs.getString(kWidgetTipDayKey);
  if (cachedDay != dayKey) return null;
  if (prefs.getString(kWidgetTipInjectedDayKey) == dayKey) return null;
  final full = prefs.getString(kWidgetTipFullTextKey)?.trim() ?? '';
  if (full.isNotEmpty) return full;
  final trimmed = prefs.getString(kWidgetTipTextKey)?.trim() ?? '';
  if (trimmed.isNotEmpty) return trimmed;
  return null;
}

/// 当日小组件 tip 是否已注入陪伴。
Future<bool> isWidgetTipInjectedToday({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kWidgetTipInjectedDayKey) ==
      _dayKey(now ?? DateTime.now());
}

/// 标记当日小组件 tip 已注入陪伴。
Future<void> markWidgetTipInjectedToday({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final dayKey = _dayKey(now ?? DateTime.now());
  await prefs.setString(kWidgetTipInjectedDayKey, dayKey);
  AppDebugLog.homeWidget('tip injected day=$dayKey');
}

Future<void> clearWidgetTipCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kWidgetTipDayKey);
  await prefs.remove(kWidgetTipTextKey);
  await prefs.remove(kWidgetTipFullTextKey);
  await prefs.remove(kWidgetTipFailDayKey);
  await prefs.remove(kWidgetTipInjectedDayKey);
}

String _dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

String _trimTipText(String raw) {
  final lines = raw.split(RegExp(r'\r?\n')).where((e) => e.trim().isNotEmpty).toList();
  var out = lines.take(_kMaxTipLines).join('\n');
  if (out.length > _kMaxTipChars) {
    out = '${out.substring(0, _kMaxTipChars)}…';
  }
  return out;
}
