import 'package:shared_preferences/shared_preferences.dart';

const _kShowRecordingDiagnosticsKey = 'show_recording_diagnostics';

/// 是否在云端按住说话时显示录音诊断面板（默认关）。
class RecordingDiagnosticsStore {
  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowRecordingDiagnosticsKey) ?? false;
  }

  static Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowRecordingDiagnosticsKey, enabled);
  }
}
