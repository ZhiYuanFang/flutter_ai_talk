import 'package:shared_preferences/shared_preferences.dart';

/// 按 history 记录 id 持久化「同步广场」开关（默认 false）。
class EventSquareSyncPreferenceStore {
  static const _keyPrefix = 'event_square_sync_v1_';

  static Future<bool> load(String historyId) async {
    if (historyId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$historyId') ?? false;
  }

  static Future<void> save(String historyId, bool enabled) async {
    if (historyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$historyId', enabled);
  }
}
