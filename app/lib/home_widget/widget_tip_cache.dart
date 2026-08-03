import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/feed_repository.dart';
import 'home_widget_payload.dart';

const kWidgetTipDayKey = 'widget_tip_day_v1';
const kWidgetTipTextKey = 'widget_tip_text_v1';
/// 未截断全文，供陪伴注入；桌面仍用 [kWidgetTipTextKey] trim 版。
const kWidgetTipFullTextKey = 'widget_tip_full_text_v1';
const kWidgetTipFailDayKey = 'widget_tip_fail_day_v1';
/// 已注入陪伴的自然日 yyyy-MM-dd；清理陪伴记录不得清除此键。
const kWidgetTipInjectedDayKey = 'widget_tip_injected_day_v1';

const _kMaxTipLines = 5;
const _kMaxTipChars = 160;

Future<HomeWidgetTipPayload?> resolveWidgetTip({
  required FeedRepository feed,
  required DateTime now,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final dayKey = _dayKey(now);
  final cachedDay = prefs.getString(kWidgetTipDayKey);
  final cachedText = prefs.getString(kWidgetTipTextKey) ?? '';
  if (cachedDay == dayKey && cachedText.isNotEmpty) {
    return HomeWidgetTipPayload(text: cachedText, fetchedAt: now);
  }
  final failDay = prefs.getString(kWidgetTipFailDayKey);
  if (failDay == dayKey) {
    if (cachedText.isNotEmpty) {
      return HomeWidgetTipPayload(text: cachedText, fetchedAt: now);
    }
    return null;
  }
  final reply = await _fetchTipInFlight(feed);
  if (reply == null || reply.trim().isEmpty) {
    await prefs.setString(kWidgetTipFailDayKey, dayKey);
    if (cachedText.isNotEmpty) {
      return HomeWidgetTipPayload(text: cachedText, fetchedAt: now);
    }
    return null;
  }
  final full = reply.trim();
  final trimmed = _trimTipText(full);
  await prefs.setString(kWidgetTipDayKey, dayKey);
  await prefs.setString(kWidgetTipTextKey, trimmed);
  await prefs.setString(kWidgetTipFullTextKey, full);
  await prefs.remove(kWidgetTipFailDayKey);
  AppDebugLog.homeWidget(
    'tip refreshed day=$dayKey trimLen=${trimmed.length} fullLen=${full.length}',
  );
  return HomeWidgetTipPayload(text: trimmed, fetchedAt: now);
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

Future<String?>? _tipFetchInFlight;

Future<String?> _fetchTipInFlight(FeedRepository feed) {
  if (_tipFetchInFlight != null) return _tipFetchInFlight!;
  return _tipFetchInFlight = feed.fetchWidgetFeedingTip().whenComplete(() {
    _tipFetchInFlight = null;
  });
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
