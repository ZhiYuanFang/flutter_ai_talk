import 'package:shared_preferences/shared_preferences.dart';

import '../data/home_input_dock_geometry.dart';

const _kEdgeKey = 'home_input_dock_v1_edge';
const _kAlongKey = 'home_input_dock_v1_along';

class HomeInputDockSnapshot {
  const HomeInputDockSnapshot({
    required this.edge,
    required this.along,
  });

  final DockEdge edge;
  final double along;
}

/// 持久化首页输入模式 dock 贴边位置。
class HomeInputDockStore {
  static Future<HomeInputDockSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final edgeRaw = prefs.getString(_kEdgeKey);
    final alongRaw = prefs.getDouble(_kAlongKey);
    final edge = parseDockEdge(edgeRaw) ?? kHomeInputDockDefaultEdge;
    final along = alongRaw != null && alongRaw.isFinite
        ? alongRaw.clamp(0.0, 1.0)
        : kHomeInputDockDefaultAlong;
    return HomeInputDockSnapshot(edge: edge, along: along);
  }

  static Future<void> save(DockEdge edge, double along) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEdgeKey, dockEdgeStorageKey(edge));
    await prefs.setDouble(_kAlongKey, along.clamp(0.0, 1.0));
  }
}
