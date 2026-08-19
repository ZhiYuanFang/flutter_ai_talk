import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/home_input_dock_geometry.dart';

/// 预测竖屏语音贴边球位置（bump 自旧 `home_input_dock_v1_*`，不继承喂养右缘默认）。
const _kEdgeKey = 'prediction_voice_dock_v1_edge';
const _kAlongKey = 'prediction_voice_dock_v1_along';
const _kFloatingKey = 'prediction_voice_dock_v1_floating';
const _kFreeXKey = 'prediction_voice_dock_v1_free_x';
const _kFreeYKey = 'prediction_voice_dock_v1_free_y';

class PredictionVoiceDockSnapshot {
  const PredictionVoiceDockSnapshot.edge({
    required this.edge,
    required this.along,
  }) : freeCenter = null;

  const PredictionVoiceDockSnapshot.free({
    required this.freeCenter,
  })  : edge = kPredictionVoiceDockDefaultEdge,
        along = kPredictionVoiceDockDefaultAlong;

  final DockEdge edge;
  final double along;
  final Offset? freeCenter;

  bool get isFloating => freeCenter != null;
}

/// 持久化预测竖屏语音贴边球位置（贴边或自由悬浮）。
class PredictionVoiceDockStore {
  static Future<PredictionVoiceDockSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kFloatingKey) == true) {
      final x = prefs.getDouble(_kFreeXKey);
      final y = prefs.getDouble(_kFreeYKey);
      if (x != null && y != null && x.isFinite && y.isFinite) {
        return PredictionVoiceDockSnapshot.free(freeCenter: Offset(x, y));
      }
    }
    final edgeRaw = prefs.getString(_kEdgeKey);
    final alongRaw = prefs.getDouble(_kAlongKey);
    final edge = parseDockEdge(edgeRaw) ?? kPredictionVoiceDockDefaultEdge;
    final along = alongRaw != null && alongRaw.isFinite
        ? alongRaw.clamp(0.0, 1.0)
        : kPredictionVoiceDockDefaultAlong;
    return PredictionVoiceDockSnapshot.edge(edge: edge, along: along);
  }

  static Future<void> saveEdge(DockEdge edge, double along) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFloatingKey, false);
    await prefs.remove(_kFreeXKey);
    await prefs.remove(_kFreeYKey);
    await prefs.setString(_kEdgeKey, dockEdgeStorageKey(edge));
    await prefs.setDouble(_kAlongKey, along.clamp(0.0, 1.0));
  }

  static Future<void> saveFree(Offset center) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFloatingKey, true);
    await prefs.setDouble(_kFreeXKey, center.dx);
    await prefs.setDouble(_kFreeYKey, center.dy);
  }
}

/// 兼容旧名（原首页输入模式 dock 存储，现仅预测语音球使用）。
typedef HomeInputDockSnapshot = PredictionVoiceDockSnapshot;
typedef HomeInputDockStore = PredictionVoiceDockStore;
