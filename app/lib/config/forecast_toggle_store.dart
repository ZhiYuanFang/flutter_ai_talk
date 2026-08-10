import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';

const kForecastDisabledEventIdsKey = 'forecast_disabled_event_ids_v1';

/// 推演开关：默认开启；仅持久化「关闭」的 eventId 集合。
class ForecastToggleStore {
  ForecastToggleStore._();

  /// 读取已关闭推演的 eventId 集合。
  static Future<Set<String>> loadDisabledIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kForecastDisabledEventIdsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return {
        for (final e in decoded)
          if (e.toString().trim().isNotEmpty) e.toString().trim(),
      };
    } catch (e) {
      AppDebugLog.homeWidget('forecast toggle load err=$e');
      return {};
    }
  }

  /// 设置某事件推演是否开启（true=开）。
  static Future<void> setEnabled(String eventId, bool enabled) async {
    final id = eventId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = await loadDisabledIds();
    if (enabled) {
      set.remove(id);
    } else {
      set.add(id);
    }
    if (set.isEmpty) {
      await prefs.remove(kForecastDisabledEventIdsKey);
    } else {
      await prefs.setString(
        kForecastDisabledEventIdsKey,
        jsonEncode(set.toList()..sort()),
      );
    }
  }

  /// 登出等场景清空。
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kForecastDisabledEventIdsKey);
  }
}
