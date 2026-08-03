import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/event_next_predictor.dart';

const kWidgetHeroSkipMapKey = 'widget_hero_skip_map_v1';

/// 小组件 hero 跳过：eventId → 跳过时的 baselineLastAt（ISO）。
class WidgetHeroSkipStore {
  WidgetHeroSkipStore._();

  /// 读取 skip 映射（eventId → baselineLastAt）。
  static Future<Map<String, DateTime>> loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kWidgetHeroSkipMapKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, DateTime>{};
      for (final e in decoded.entries) {
        final id = e.key.toString().trim();
        if (id.isEmpty) continue;
        final at = DateTime.tryParse(e.value.toString());
        if (at == null) continue;
        out[id] = at;
      }
      return out;
    } catch (e) {
      AppDebugLog.homeWidget('skip load err=$e');
      return {};
    }
  }

  static Future<void> _saveMap(Map<String, DateTime> map) async {
    final prefs = await SharedPreferences.getInstance();
    if (map.isEmpty) {
      await prefs.remove(kWidgetHeroSkipMapKey);
      return;
    }
    final encoded = <String, String>{
      for (final e in map.entries) e.key: e.value.toUtc().toIso8601String(),
    };
    await prefs.setString(kWidgetHeroSkipMapKey, jsonEncode(encoded));
  }

  /// 记录跳过：以该事件当前 lastAt 为基线。
  static Future<void> skipEvent({
    required String eventId,
    required DateTime baselineLastAt,
  }) async {
    final id = eventId.trim();
    if (id.isEmpty) return;
    final map = await loadMap();
    map[id] = baselineLastAt;
    await _saveMap(map);
    AppDebugLog.homeWidget('skip add eventId=$id baseline=$baselineLastAt');
  }

  /// 登出或显式清空。
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kWidgetHeroSkipMapKey);
    AppDebugLog.homeWidget('skip cleared');
  }

  /// 按预测 lastAt 解除已有新记录的 skip，并返回仍有效的 skip id 集合。
  static Future<Set<String>> reconcileAndActiveIds(
    List<EventNextPrediction> predictions,
  ) async {
    final map = await loadMap();
    if (map.isEmpty) return {};
    final byId = {for (final p in predictions) p.eventId: p};
    var changed = false;
    final stale = <String>[];
    for (final e in map.entries) {
      final p = byId[e.key];
      if (p == null) continue;
      // 有新记录：lastAt 晚于跳过基线则解除
      if (p.lastAt.isAfter(e.value)) {
        stale.add(e.key);
      }
    }
    for (final id in stale) {
      map.remove(id);
      changed = true;
      AppDebugLog.homeWidget('skip clear by history eventId=$id');
    }
    if (changed) await _saveMap(map);
    return map.keys.toSet();
  }
}

/// 从预测列表去掉仍 skip 的项（保持 nextAt 序）。
List<EventNextPrediction> filterPredictionsExcludingSkipped(
  List<EventNextPrediction> predictions,
  Set<String> skippedIds,
) {
  if (skippedIds.isEmpty) return predictions;
  return [
    for (final p in predictions)
      if (!skippedIds.contains(p.eventId)) p,
  ];
}
