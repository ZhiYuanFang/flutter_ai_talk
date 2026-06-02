import 'package:shared_preferences/shared_preferences.dart';

const _kShowRecordingDiagnosticsKey = 'show_recording_diagnostics';

/// 源码级总开关：设为 `true` 并恢复设置页「显示录音数据」开关后，prefs 读写才会生效。
const kRecordingDiagnosticsFeatureEnabled = false;

/// 是否在云端按住说话时显示录音诊断面板（默认关）。
class RecordingDiagnosticsStore {
  static Future<bool> load() async {
    if (!kRecordingDiagnosticsFeatureEnabled) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowRecordingDiagnosticsKey) ?? false;
  }

  static Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowRecordingDiagnosticsKey, enabled);
  }
}
