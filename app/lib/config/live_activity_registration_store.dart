import 'package:shared_preferences/shared_preferences.dart';

const _kImminentPtsOkAtMs = 'la_pts_ok_imminent_at_ms_v1';
const _kTimingPtsOkAtMs = 'la_pts_ok_timing_at_ms_v1';

/// 持久化两类 Push-to-Start 末次成功时间（不含 token）。
class LiveActivityRegistrationStore {
  LiveActivityRegistrationStore._();

  /// 读取 imminent 末次成功时间。
  static Future<DateTime?> loadImminentOkAt() => _loadMs(_kImminentPtsOkAtMs);

  /// 读取 timing 末次成功时间。
  static Future<DateTime?> loadTimingOkAt() => _loadMs(_kTimingPtsOkAtMs);

  /// 写入 imminent 成功时间。
  static Future<void> saveImminentOkAt(DateTime at) =>
      _saveMs(_kImminentPtsOkAtMs, at);

  /// 写入 timing 成功时间。
  static Future<void> saveTimingOkAt(DateTime at) =>
      _saveMs(_kTimingPtsOkAtMs, at);

  static Future<DateTime?> _loadMs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(key);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> _saveMs(String key, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, at.millisecondsSinceEpoch);
  }
}
