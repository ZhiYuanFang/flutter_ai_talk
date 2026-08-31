import 'dart:ui';

import 'edge_dock_geometry.dart';
import 'edge_dock_placement.dart';

/// 首页模式球占位 id（sticky；历史，喂养 dock 已移除）。
const kEdgeDockOccupancyModeId = 'home-input-mode';

/// 预测竖屏语音球占位 id（sticky）。
const kEdgeDockOccupancyPredictionVoiceId = 'prediction-voice';

/// 预测竖屏广场入口球占位 id（sticky）。
const kEdgeDockOccupancyUcgSquareId = 'ucg-square';

/// 首页 tip 球占位 id（非 sticky）。
const kEdgeDockOccupancyTipId = 'home-tip';

class _OccupancyEntry {
  _OccupancyEntry({
    required this.id,
    required this.placement,
    required this.sticky,
    required this.diameter,
  });

  final String id;
  EdgeDockPlacement placement;
  bool sticky;
  double diameter;
}

/// 共享贴边球占位表：注册 / 解冲突（松手时推非 sticky）。
class EdgeDockOccupancy {
  EdgeDockOccupancy();

  /// 进程内共享实例（壳默认使用）。
  static final EdgeDockOccupancy instance = EdgeDockOccupancy();

  final _entries = <String, _OccupancyEntry>{};

  void register(
    String id, {
    required EdgeDockPlacement placement,
    bool sticky = false,
    double diameter = kDefaultEdgeDockDiameter,
  }) {
    final existing = _entries[id];
    if (existing != null) {
      existing.placement = placement;
      existing.sticky = sticky;
      existing.diameter = diameter;
      return;
    }
    _entries[id] = _OccupancyEntry(
      id: id,
      placement: placement,
      sticky: sticky,
      diameter: diameter,
    );
  }

  void unregister(String id) {
    _entries.remove(id);
  }

  /// 将 [desired] 解析为与其它已注册球不重叠的 placement；sticky 障碍不动。
  EdgeDockPlacement resolve({
    required String id,
    required EdgeDockPlacement desired,
    required Rect bounds,
    bool allowTopBottom = true,
    double diameter = kDefaultEdgeDockDiameter,
    double gap = kDefaultEdgeDockGap,
  }) {
    // 解析期间暂用 desired 作为自身占位参与距离计算时排除 id
    final obstacles = <({Offset center, double diameter})>[];
    for (final e in _entries.values) {
      if (e.id == id) continue;
      obstacles.add((
        center: edgeDockPlacementCenter(
          e.placement,
          bounds: bounds,
          diameter: e.diameter,
        ),
        diameter: e.diameter,
      ));
    }
    if (obstacles.isEmpty) return desired;

    bool overlaps(Offset c) {
      for (final o in obstacles) {
        if (dockCirclesOverlap(
          c,
          o.center,
          diameterA: diameter,
          diameterB: o.diameter,
          gap: gap,
        )) {
          return true;
        }
      }
      return false;
    }

    if (desired.isFloating && desired.freeCenter != null) {
      return _resolveFloating(
        desired: desired,
        bounds: bounds,
        diameter: diameter,
        gap: gap,
        overlaps: overlaps,
        obstacles: obstacles,
      );
    }

    return _resolveEdge(
      desired: desired,
      bounds: bounds,
      allowTopBottom: allowTopBottom,
      diameter: diameter,
      gap: gap,
      overlaps: overlaps,
      obstacles: obstacles,
    );
  }

  EdgeDockPlacement _resolveEdge({
    required EdgeDockPlacement desired,
    required Rect bounds,
    required bool allowTopBottom,
    required double diameter,
    required double gap,
    required bool Function(Offset c) overlaps,
    required List<({Offset center, double diameter})> obstacles,
  }) {
    final edges = <DockEdge>[
      desired.edge,
      ...DockEdge.values.where((e) {
        if (e == desired.edge) return false;
        if (!allowTopBottom && (e == DockEdge.top || e == DockEdge.bottom)) {
          return false;
        }
        return true;
      }),
    ];

    for (final edge in edges) {
      final step = dockMinAlongSeparation(
        edge: edge,
        bounds: bounds,
        diameter: diameter,
        gap: gap,
      );
      // 从 desired.along 起双向扫描
      final base = edge == desired.edge ? desired.along : 0.5;
      final candidates = <double>[base];
      for (var i = 1; i * step <= 1.0 + 1e-6; i++) {
        candidates.add((base + i * step).clamp(0.0, 1.0));
        candidates.add((base - i * step).clamp(0.0, 1.0));
      }
      // 去重保序
      final seen = <double>{};
      for (final along in candidates) {
        final key = (along * 1000).round() / 1000;
        if (!seen.add(key)) continue;
        final p = EdgeDockPlacement.edge(
          kind: desired.isEngaged
              ? EdgeDockKind.edgeEngaged
              : EdgeDockKind.edgePeek,
          edge: edge,
          along: along,
        );
        final c = edgeDockPlacementCenter(
          p,
          bounds: bounds,
          diameter: diameter,
        );
        if (!overlaps(c)) return p;
      }
    }

    // 贴边扫不到：退回浮空并外推
    final fallbackCenter = dockCircleCenterForFullCircle(
      edge: desired.edge,
      along: desired.along,
      bounds: bounds,
      diameter: diameter,
    );
    return _resolveFloating(
      desired: EdgeDockPlacement.floating(freeCenter: fallbackCenter),
      bounds: bounds,
      diameter: diameter,
      gap: gap,
      overlaps: overlaps,
      obstacles: obstacles,
    );
  }

  EdgeDockPlacement _resolveFloating({
    required EdgeDockPlacement desired,
    required Rect bounds,
    required double diameter,
    required double gap,
    required bool Function(Offset c) overlaps,
    required List<({Offset center, double diameter})> obstacles,
  }) {
    var center = clampDockCenterForDrag(
      desired.freeCenter ?? Offset(bounds.center.dx, bounds.center.dy),
      bounds,
      diameter: diameter,
    );
    for (var iter = 0; iter < 24 && overlaps(center); iter++) {
      // 相对最近障碍外推
      Offset? nearest;
      var nearestDist = double.infinity;
      var nearestDia = diameter;
      for (final o in obstacles) {
        final d = (center - o.center).distance;
        if (d < nearestDist) {
          nearestDist = d;
          nearest = o.center;
          nearestDia = o.diameter;
        }
      }
      if (nearest == null) break;
      final minDist = diameter / 2 + nearestDia / 2 + gap;
      var dir = center - nearest;
      if (dir.distance < 1e-3) {
        dir = const Offset(1, 0);
      }
      final unit = dir / dir.distance;
      center = clampDockCenterForDrag(
        nearest + unit * (minDist + 1),
        bounds,
        diameter: diameter,
      );
    }
    return EdgeDockPlacement.floating(freeCenter: center);
  }
}
