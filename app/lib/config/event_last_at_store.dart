import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 宝宝维度：目录根 eventId → 本机曾见真喂养最新发生时刻（与回忆种子隔离）。
class EventLastAtStore {
  EventLastAtStore._();

  static String prefsKey(String deviceNo) =>
      'event_last_at_v1_${deviceNo.trim()}';

  /// 读取 deviceNo 下全部 tip；坏数据返回空 map。
  static Future<Map<String, DateTime>> load(String deviceNo) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey(dn));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, DateTime>{};
      for (final e in decoded.entries) {
        final id = e.key.toString().trim();
        if (id.isEmpty) continue;
        final s = e.value?.toString() ?? '';
        if (s.isEmpty) continue;
        final t = DateTime.tryParse(s)?.toLocal();
        if (t == null) continue;
        out[id] = t;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// 整表写盘（根 → UTC ISO8601）。
  static Future<void> save(String deviceNo, Map<String, DateTime> map) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (map.isEmpty) {
      await prefs.remove(prefsKey(dn));
      return;
    }
    final encoded = <String, String>{
      for (final e in map.entries)
        if (e.key.trim().isNotEmpty)
          e.key.trim(): e.value.toUtc().toIso8601String(),
    };
    if (encoded.isEmpty) {
      await prefs.remove(prefsKey(dn));
      return;
    }
    await prefs.setString(prefsKey(dn), jsonEncode(encoded));
  }

  /// 注销/注销时清掉该宝宝 tip 缓存。
  static Future<void> clearDevice(String deviceNo) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey(dn));
  }
}
