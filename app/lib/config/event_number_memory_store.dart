import 'package:shared_preferences/shared_preferences.dart';

/// 按事件 ID 记忆上次确认的 number 用量（如奶量 ml），供下次添加时滚轮初始位置。
class EventNumberMemoryStore {
  static const _keyPrefix = 'event_number_last_v1_';

  static Future<int?> load(String eventId) async {
    if (eventId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('$_keyPrefix$eventId')) return null;
    return prefs.getInt('$_keyPrefix$eventId');
  }

  static Future<void> save(String eventId, int value) async {
    if (eventId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$eventId', value);
  }
}
