import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 全局事件按钮点击用量（成功添加后 +1），供首页排序。
class EventButtonUsageStore {
  static const _key = 'event_button_usage_v1';

  static Future<Map<String, int>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final id = entry.key;
        final value = entry.value;
        if (id is String && value is num) {
          out[id] = value.toInt();
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> increment(String eventId) async {
    if (eventId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final counts = await loadAll();
    counts[eventId] = (counts[eventId] ?? 0) + 1;
    await prefs.setString(_key, jsonEncode(counts));
  }
}
