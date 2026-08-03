import 'dart:ui';

import 'edge_dock_geometry.dart';

/// 壳放置形态。
enum EdgeDockKind { edgePeek, edgeEngaged, floating }

/// 当前放置快照（供宿主持久化 / tip 同步 / 占位表）。
class EdgeDockPlacement {
  const EdgeDockPlacement.edge({
    required this.kind,
    required this.edge,
    required this.along,
  }) : freeCenter = null;

  const EdgeDockPlacement.floating({
    required Offset this.freeCenter,
  })  : kind = EdgeDockKind.floating,
        edge = DockEdge.right,
        along = 0.5;

  final EdgeDockKind kind;
  final DockEdge edge;
  final double along;
  final Offset? freeCenter;

  bool get isFloating => kind == EdgeDockKind.floating;
  bool get isPeek => kind == EdgeDockKind.edgePeek;
  bool get isEngaged => kind == EdgeDockKind.edgeEngaged;
}

/// 占位用圆心：peek 用半圆圆心，engaged/浮空用全圆或 free。
Offset edgeDockPlacementCenter(
  EdgeDockPlacement p, {
  required Rect bounds,
  double diameter = kDefaultEdgeDockDiameter,
}) {
  if (p.isFloating && p.freeCenter != null) {
    return p.freeCenter!;
  }
  if (p.isEngaged) {
    return dockCircleCenterForFullCircle(
      edge: p.edge,
      along: p.along,
      bounds: bounds,
      diameter: diameter,
    );
  }
  return dockCircleCenterForSnapped(
    edge: p.edge,
    along: p.along,
    bounds: bounds,
    diameter: diameter,
  );
}
