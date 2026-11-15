import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 预约 next/last 按 deviceNo 落盘（先展示后静默刷新）。
///
/// 存盘形态为 JSON map；业务类型转换在 provider 侧完成，避免循环 import。
class AppointmentLocalCacheStore {
  AppointmentLocalCacheStore._();

  static String nextPrefsKey(String deviceNo) =>
      'appointment_next_v1_${deviceNo.trim()}';

  static String lastPrefsKey(String deviceNo) =>
      'appointment_last_v1_${deviceNo.trim()}';

  /// 读取 next：根 id → `{nextAtSec, remark}`。
  static Future<Map<String, Map<String, Object?>>> loadNextRaw(
    String deviceNo,
  ) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(nextPrefsKey(dn));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, Map<String, Object?>>{};
      for (final e in decoded.entries) {
        final id = e.key.toString().trim();
        if (id.isEmpty || e.value is! Map) continue;
        final v = Map<String, Object?>.from(e.value as Map);
        out[id] = v;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// 整表写 next raw。
  static Future<void> saveNextRaw(
    String deviceNo,
    Map<String, Map<String, Object?>> map,
  ) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (map.isEmpty) {
      await prefs.remove(nextPrefsKey(dn));
      return;
    }
    final encoded = <String, Object>{};
    for (final e in map.entries) {
      final id = e.key.trim();
      if (id.isEmpty) continue;
      encoded[id] = e.value;
    }
    if (encoded.isEmpty) {
      await prefs.remove(nextPrefsKey(dn));
      return;
    }
    await prefs.setString(nextPrefsKey(dn), jsonEncode(encoded));
  }

  /// 读取 last：根 id → `{at?, remark, empty?}`。
  static Future<Map<String, Map<String, Object?>>> loadLastRaw(
    String deviceNo,
  ) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastPrefsKey(dn));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, Map<String, Object?>>{};
      for (final e in decoded.entries) {
        final id = e.key.toString().trim();
        if (id.isEmpty || e.value is! Map) continue;
        out[id] = Map<String, Object?>.from(e.value as Map);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// 整表写 last raw。
  static Future<void> saveLastRaw(
    String deviceNo,
    Map<String, Map<String, Object?>> map,
  ) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (map.isEmpty) {
      await prefs.remove(lastPrefsKey(dn));
      return;
    }
    final encoded = <String, Object>{};
    for (final e in map.entries) {
      final id = e.key.trim();
      if (id.isEmpty) continue;
      encoded[id] = e.value;
    }
    if (encoded.isEmpty) {
      await prefs.remove(lastPrefsKey(dn));
      return;
    }
    await prefs.setString(lastPrefsKey(dn), jsonEncode(encoded));
  }

  /// 注销/切号清盘。
  static Future<void> clearDevice(String deviceNo) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(nextPrefsKey(dn));
    await prefs.remove(lastPrefsKey(dn));
  }
}
