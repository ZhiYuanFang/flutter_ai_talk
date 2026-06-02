import 'package:shared_preferences/shared_preferences.dart';

const _kHomeInputChannelKey = 'home_input_channel_v1';

/// 持久化首页输入模式（`voice` / `text` / `buttons`）。
/// 移动端恢复时忽略 `text`；Web 仍可使用 `text`。
class HomeInputChannelStore {
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kHomeInputChannelKey);
  }

  static Future<void> save(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHomeInputChannelKey, channel);
  }
}
