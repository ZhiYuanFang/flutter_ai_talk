import 'package:shared_preferences/shared_preferences.dart';

const _kGreetingDayKey = 'companion_greeting_day_v1';

/// 智能陪伴「我来啦」当日首次门闩（本地日历日 yyyy-MM-dd）。
class CompanionGreetingStore {
  CompanionGreetingStore._();

  static String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// 今日是否已问候（含因 tip 注入而标记）。
  static Future<bool> hasGreetedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGreetingDayKey) == _todayKey();
  }

  /// 标记今日已问候。
  static Future<void> markGreetedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGreetingDayKey, _todayKey());
  }
}
