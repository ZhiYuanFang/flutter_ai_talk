import 'package:shared_preferences/shared_preferences.dart';

const _kPrivacyPolicyConsentKey = 'privacy_policy_consent_v1';

/// 首启隐私政策是否已同意（同意前不得冷启动联网采集）。
class PrivacyPolicyConsentStore {
  PrivacyPolicyConsentStore._();

  /// 是否已持久化同意。
  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrivacyPolicyConsentKey) ?? false;
  }

  /// 写入同意（仅「同意并继续」调用）。
  static Future<void> saveAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrivacyPolicyConsentKey, true);
  }
}
