import 'package:shared_preferences/shared_preferences.dart';

const _kCompanionInputModeKey = 'companion_input_mode_v1';

/// 智能陪伴输入模式：文字 / 按住说话（与喂养 HomeInputChannel 分离）。
enum CompanionInputMode {
  text,
  voice,
}

/// 持久化陪伴输入模式；Web 调用方应忽略 voice。
class CompanionInputModeStore {
  CompanionInputModeStore._();

  static Future<CompanionInputMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCompanionInputModeKey);
    return switch (raw) {
      'voice' => CompanionInputMode.voice,
      'text' => CompanionInputMode.text,
      _ => null,
    };
  }

  static Future<void> save(CompanionInputMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCompanionInputModeKey,
      mode == CompanionInputMode.voice ? 'voice' : 'text',
    );
  }
}
