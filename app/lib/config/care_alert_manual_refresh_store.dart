import 'package:shared_preferences/shared_preferences.dart';

/// 值得留意「今日已手动成功刷新」持久化（上海日 + deviceNo）。
const _kManualOkPrefix = 'care_alert_manual_ok_v1_';

class CareAlertManualRefreshStore {
  CareAlertManualRefreshStore._();

  static String _key(String deviceNo, String dayKey) =>
      '$_kManualOkPrefix${deviceNo.trim()}_$dayKey';

  /// 该设备在指定上海日是否已业务成功手动刷新。
  static Future<bool> hasSucceeded({
    required String deviceNo,
    required String dayKey,
  }) async {
    final dn = deviceNo.trim();
    final day = dayKey.trim();
    if (dn.isEmpty || day.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(dn, day)) == true;
  }

  /// 标记该设备当日手动刷新业务成功。
  static Future<void> markSucceeded({
    required String deviceNo,
    required String dayKey,
  }) async {
    final dn = deviceNo.trim();
    final day = dayKey.trim();
    if (dn.isEmpty || day.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(dn, day), true);
  }
}
