import 'package:shared_preferences/shared_preferences.dart';

const _kUcgAiPolishConsentKey = 'ucg_ai_polish_consent_v1';

/// 用户是否已同意 UGC AI 润笔（所选图片 + 正文发送至第三方 AI）处理告知。
class UcgAiPolishConsentStore {
  UcgAiPolishConsentStore._();

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUcgAiPolishConsentKey) ?? false;
  }

  static Future<void> saveAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUcgAiPolishConsentKey, true);
  }
}
