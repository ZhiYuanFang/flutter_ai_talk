import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 键字面量保持不变，避免升级后丢失「不再提示」状态。
const _kNotifyBannerDismissKey = 'status_banner_dismiss_content_key_v1';

/// 可取消公告的「不再提示」持久化；contentKey = trim(title)+\n+trim(message)。
/// active 从 false 再次变为 true 时服务端不会清除此项，同文案仍被抑制。
class NotifyBannerDismissStore {
  NotifyBannerDismissStore._();

  static Future<bool> isDismissed(String contentKey) async {
    final key = contentKey.trim();
    if (key.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNotifyBannerDismissKey) == key;
  }

  static Future<void> saveDismissed(String contentKey) async {
    final key = contentKey.trim();
    if (key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotifyBannerDismissKey, key);
  }
}
