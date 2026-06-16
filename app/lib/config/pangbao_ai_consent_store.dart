import 'package:shared_preferences/shared_preferences.dart';

const _kPangbaoAiConsentKey = 'pangbao_ai_consent_v1';

/// 用户是否已同意胖宝 AI（7 天摘要 + thinking 展示 + DeepSeek）独立告知。
class PangbaoAiConsentStore {
  PangbaoAiConsentStore._();

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPangbaoAiConsentKey) ?? false;
  }

  static Future<void> saveAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPangbaoAiConsentKey, true);
  }
}
