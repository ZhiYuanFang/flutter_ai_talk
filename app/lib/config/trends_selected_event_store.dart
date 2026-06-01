import 'package:shared_preferences/shared_preferences.dart';

/// 趋势中心上次选中事件记忆。
class TrendsSelectedEventStore {
  static const _key = 'trends_selected_event_v1';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static Future<void> save(String eventId) async {
    final key = eventId.trim();
    if (key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key);
  }
}
