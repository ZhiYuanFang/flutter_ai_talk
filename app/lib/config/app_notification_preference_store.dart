import 'package:shared_preferences/shared_preferences.dart';

const _kAppNotificationPreferenceKey = 'app_notification_preference_enabled_v1';

/// 应用层消息通知总开关（默认开启，对齐登录即尝试注册）。
class AppNotificationPreferenceStore {
  AppNotificationPreferenceStore._();

  /// 读取偏好；缺省为 true。
  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppNotificationPreferenceKey) ?? true;
  }

  /// 持久化偏好。
  static Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppNotificationPreferenceKey, enabled);
  }
}
