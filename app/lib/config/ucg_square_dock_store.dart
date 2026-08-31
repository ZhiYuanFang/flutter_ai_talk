import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/edge_dock_geometry.dart';

/// 广场贴边球默认：右侧、纵向居中 peek。
const kUcgSquareDockDefaultEdge = DockEdge.right;
const kUcgSquareDockDefaultAlong = 0.5;

const _kEdgeKey = 'ucg_square_dock_v1_edge';
const _kAlongKey = 'ucg_square_dock_v1_along';
const _kFloatingKey = 'ucg_square_dock_v1_floating';
const _kFreeXKey = 'ucg_square_dock_v1_free_x';
const _kFreeYKey = 'ucg_square_dock_v1_free_y';

/// 广场贴边球位置快照（贴边或浮空）。
class UcgSquareDockSnapshot {
  const UcgSquareDockSnapshot.edge({
    required this.edge,
    required this.along,
  }) : freeCenter = null;

  const UcgSquareDockSnapshot.free({
    required this.freeCenter,
  })  : edge = kUcgSquareDockDefaultEdge,
        along = kUcgSquareDockDefaultAlong;

  final DockEdge edge;
  final double along;
  final Offset? freeCenter;

  bool get isFloating => freeCenter != null;
}

/// 持久化预测竖屏广场贴边球位置（独立于语音球 keys）。
class UcgSquareDockStore {
  static Future<UcgSquareDockSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kFloatingKey) == true) {
      final x = prefs.getDouble(_kFreeXKey);
      final y = prefs.getDouble(_kFreeYKey);
      if (x != null && y != null && x.isFinite && y.isFinite) {
        return UcgSquareDockSnapshot.free(freeCenter: Offset(x, y));
      }
    }
    final edgeRaw = prefs.getString(_kEdgeKey);
    final alongRaw = prefs.getDouble(_kAlongKey);
    final edge = parseDockEdge(edgeRaw) ?? kUcgSquareDockDefaultEdge;
    final along = alongRaw != null && alongRaw.isFinite
        ? alongRaw.clamp(0.0, 1.0)
        : kUcgSquareDockDefaultAlong;
    return UcgSquareDockSnapshot.edge(edge: edge, along: along);
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
