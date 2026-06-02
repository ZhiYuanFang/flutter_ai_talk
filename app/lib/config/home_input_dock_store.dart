import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/home_input_dock_geometry.dart';

const _kEdgeKey = 'home_input_dock_v1_edge';
const _kAlongKey = 'home_input_dock_v1_along';
const _kFloatingKey = 'home_input_dock_v1_floating';
const _kFreeXKey = 'home_input_dock_v1_free_x';
const _kFreeYKey = 'home_input_dock_v1_free_y';

class HomeInputDockSnapshot {
  const HomeInputDockSnapshot.edge({
    required this.edge,
    required this.along,
  }) : freeCenter = null;

  const HomeInputDockSnapshot.free({
    required this.freeCenter,
  })  : edge = kHomeInputDockDefaultEdge,
        along = kHomeInputDockDefaultAlong;

  final DockEdge edge;
  final double along;
  final Offset? freeCenter;

  bool get isFloating => freeCenter != null;
}

/// 持久化首页输入模式 dock 位置（贴边或自由悬浮）。
class HomeInputDockStore {
  static Future<HomeInputDockSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kFloatingKey) == true) {
      final x = prefs.getDouble(_kFreeXKey);
      final y = prefs.getDouble(_kFreeYKey);
      if (x != null && y != null && x.isFinite && y.isFinite) {
        return HomeInputDockSnapshot.free(freeCenter: Offset(x, y));
      }
    }
    final edgeRaw = prefs.getString(_kEdgeKey);
    final alongRaw = prefs.getDouble(_kAlongKey);
    final edge = parseDockEdge(edgeRaw) ?? kHomeInputDockDefaultEdge;
    final along = alongRaw != null && alongRaw.isFinite
        ? alongRaw.clamp(0.0, 1.0)
        : kHomeInputDockDefaultAlong;
    return HomeInputDockSnapshot.edge(edge: edge, along: along);
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

  /// 兼容旧调用。
  static Future<void> save(DockEdge edge, double along) => saveEdge(edge, along);
}
