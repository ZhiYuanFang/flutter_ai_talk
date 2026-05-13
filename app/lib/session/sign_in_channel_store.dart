import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsKey = 'pangbao_sign_in_channel_v1';

/// 与网关保存分支相关的登录来源（持久化于 SharedPreferences）。
enum SignInChannel {
  device,
  wechat,
  unknown,
}

extension SignInChannelWire on SignInChannel {
  static SignInChannel parse(String? raw) {
    switch (raw) {
      case 'device':
        return SignInChannel.device;
      case 'wechat':
        return SignInChannel.wechat;
      default:
        return SignInChannel.unknown;
    }
  }

  String? get wireValue => switch (this) {
        SignInChannel.device => 'device',
        SignInChannel.wechat => 'wechat',
        SignInChannel.unknown => null,
      };
}

/// 读写登录渠道（与 access token 独立）。
class SignInChannelStore {
  SignInChannelStore._();

  static Future<SignInChannel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SignInChannelWire.parse(prefs.getString(_kPrefsKey));
  }

  static Future<void> save(SignInChannel channel) async {
    final v = channel.wireValue;
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove(_kPrefsKey);
      return;
    }
    await prefs.setString(_kPrefsKey, v);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
  }
}
