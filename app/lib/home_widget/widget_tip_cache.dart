import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/feed_repository.dart';
import 'home_widget_payload.dart';

const kWidgetTipDayKey = 'widget_tip_day_v1';
const kWidgetTipTextKey = 'widget_tip_text_v1';
const kWidgetTipFailDayKey = 'widget_tip_fail_day_v1';

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
  final trimmed = _trimTipText(reply.trim());
  await prefs.setString(kWidgetTipDayKey, dayKey);
  await prefs.setString(kWidgetTipTextKey, trimmed);
  await prefs.remove(kWidgetTipFailDayKey);
  AppDebugLog.homeWidget('tip refreshed day=$dayKey len=${trimmed.length}');
  return HomeWidgetTipPayload(text: trimmed, fetchedAt: now);
}

Future<void> clearWidgetTipCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kWidgetTipDayKey);
  await prefs.remove(kWidgetTipTextKey);
  await prefs.remove(kWidgetTipFailDayKey);
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
