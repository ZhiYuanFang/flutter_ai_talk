import 'package:shared_preferences/shared_preferences.dart';

const _kAiChatDataConsentKey = 'ai_chat_data_consent_v1';

/// 用户是否已同意 AI 对话数据（输入 + 近期喂养记录发送至第三方 AI）处理告知。
class AiChatDataConsentStore {
  AiChatDataConsentStore._();

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAiChatDataConsentKey) ?? false;
  }

  static Future<void> saveAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiChatDataConsentKey, true);
  }
}
