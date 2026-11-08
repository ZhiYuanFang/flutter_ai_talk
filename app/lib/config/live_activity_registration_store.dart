import 'package:shared_preferences/shared_preferences.dart';

const _kUnifiedPtsOkAtMs = 'la_pts_ok_unified_at_ms_v1';
/// 旧双轨键：hydrate 时兼容读取一次。
const _kLegacyImminentPtsOkAtMs = 'la_pts_ok_imminent_at_ms_v1';
const _kLegacyTimingPtsOkAtMs = 'la_pts_ok_timing_at_ms_v1';

/// 持久化统一轨 Push-to-Start 末次成功时间（不含 token）。
class LiveActivityRegistrationStore {
  LiveActivityRegistrationStore._();

  /// 读取统一轨末次成功时间（兼容旧双轨任一成功）。
  static Future<DateTime?> loadPushToStartOkAt() async {
    final unified = await _loadMs(_kUnifiedPtsOkAtMs);
    if (unified != null) return unified;
    final imm = await _loadMs(_kLegacyImminentPtsOkAtMs);
    final tim = await _loadMs(_kLegacyTimingPtsOkAtMs);
    if (imm != null && tim != null) {
      return imm.isAfter(tim) ? imm : tim;
    }
    return imm ?? tim;
  }

  /// 写入统一轨成功时间。
  static Future<void> savePushToStartOkAt(DateTime at) =>
      _saveMs(_kUnifiedPtsOkAtMs, at);

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
