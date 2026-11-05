import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/edge_dock_geometry.dart';

const _kEdgeKey = 'home_widget_dock_v1_edge';
const _kAlongKey = 'home_widget_dock_v1_along';
const _kFloatingKey = 'home_widget_dock_v1_floating';
const _kFreeXKey = 'home_widget_dock_v1_free_x';
const _kFreeYKey = 'home_widget_dock_v1_free_y';

/// 桌面小组件贴边球位置快照。
class HomeWidgetDockSnapshot {
  const HomeWidgetDockSnapshot.edge({
    required this.edge,
    required this.along,
  }) : freeCenter = null;

  const HomeWidgetDockSnapshot.free({
    required this.freeCenter,
  })  : edge = kHomeWidgetDockDefaultEdge,
        along = kHomeWidgetDockDefaultAlong;

  final DockEdge edge;
  final double along;
  final Offset? freeCenter;

  bool get isFloating => freeCenter != null;
}

/// 持久化预测竖屏小组件贴边球位置（独立于语音/广场 keys）。
class HomeWidgetDockStore {
  static Future<HomeWidgetDockSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kFloatingKey) == true) {
      final x = prefs.getDouble(_kFreeXKey);
      final y = prefs.getDouble(_kFreeYKey);
      if (x != null && y != null && x.isFinite && y.isFinite) {
        return HomeWidgetDockSnapshot.free(freeCenter: Offset(x, y));
      }
    }
    final edgeRaw = prefs.getString(_kEdgeKey);
    final alongRaw = prefs.getDouble(_kAlongKey);
    final edge = parseDockEdge(edgeRaw) ?? kHomeWidgetDockDefaultEdge;
    final along = alongRaw != null && alongRaw.isFinite
        ? alongRaw.clamp(0.0, 1.0)
        : kHomeWidgetDockDefaultAlong;
    return HomeWidgetDockSnapshot.edge(edge: edge, along: along);
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
