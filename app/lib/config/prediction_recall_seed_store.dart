import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/prediction_recall_seed.dart';

/// 预测回忆种子本地持久化（与喂养 history / history_media 隔离）。
class PredictionRecallSeedStore {
  static const _prefsKey = 'prediction_recall_seeds_v1';

  static Future<Map<String, PredictionRecallSeed>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final out = <String, PredictionRecallSeed>{};
      for (final e in decoded.entries) {
        final v = e.value;
        if (v is! Map) continue;
        final seed = PredictionRecallSeed.fromJson(
          Map<String, dynamic>.from(v),
        );
        if (seed == null) continue;
        out[seed.rootEventId] = seed;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAll(Map<String, PredictionRecallSeed> seeds) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      for (final e in seeds.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<void> upsert(PredictionRecallSeed seed) async {
    final all = await loadAll();
    all[seed.rootEventId] = seed;
    await saveAll(all);
  }

  static Future<void> remove(String rootEventId) async {
    final all = await loadAll();
    if (all.remove(rootEventId) == null) return;
    await saveAll(all);
  }

  static Future<void> removeMany(Iterable<String> rootEventIds) async {
    final all = await loadAll();
    var changed = false;
    for (final id in rootEventIds) {
      if (all.remove(id) != null) changed = true;
    }
    if (changed) await saveAll(all);
  }
}
