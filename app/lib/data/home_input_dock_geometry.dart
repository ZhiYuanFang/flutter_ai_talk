import 'dart:ui';

/// 输入模式 dock 吸附边。
enum DockEdge { top, bottom, left, right }

/// 贴边半圆控件直径。
const kHomeInputDockDiameter = 48.0;

const kHomeInputDockRadius = kHomeInputDockDiameter / 2;

const kHomeInputDockDefaultEdge = DockEdge.right;

const kHomeInputDockDefaultAlong = 0.75;

DockEdge? parseDockEdge(String? raw) {
  return switch (raw) {
    'top' => DockEdge.top,
    'bottom' => DockEdge.bottom,
    'left' => DockEdge.left,
    'right' => DockEdge.right,
    _ => null,
  };
}

String dockEdgeStorageKey(DockEdge edge) {
  return switch (edge) {
    DockEdge.top => 'top',
    DockEdge.bottom => 'bottom',
    DockEdge.left => 'left',
    DockEdge.right => 'right',
  };
}

/// 吸附状态下圆心坐标（圆心落在边缘线上，半圆在屏内）。
Offset dockCircleCenterForSnapped({
  required DockEdge edge,
  required double along,
  required Rect bounds,
}) {
  final margin = kHomeInputDockRadius;
  final spanH = (bounds.height - 2 * margin).clamp(1.0, double.infinity);
  final spanW = (bounds.width - 2 * margin).clamp(1.0, double.infinity);
  final t = along.clamp(0.0, 1.0);
  return switch (edge) {
    DockEdge.left => Offset(bounds.left, bounds.top + margin + t * spanH),
    DockEdge.right => Offset(bounds.right, bounds.top + margin + t * spanH),
    DockEdge.top => Offset(bounds.left + margin + t * spanW, bounds.top),
    DockEdge.bottom => Offset(bounds.left + margin + t * spanW, bounds.bottom),
  };
}

/// 自由坐标吸附到最近边，并计算沿边归一化位置。
({DockEdge edge, double along}) snapDockToNearestEdge(
  Offset center,
  Rect bounds, {
  bool allowTopBottom = true,
}) {
  final distances = <DockEdge, double>{
    DockEdge.top: (center.dy - bounds.top).abs(),
    DockEdge.bottom: (bounds.bottom - center.dy).abs(),
    DockEdge.left: (center.dx - bounds.left).abs(),
    DockEdge.right: (bounds.right - center.dx).abs(),
  };
  if (!allowTopBottom) {
    distances.remove(DockEdge.top);
    distances.remove(DockEdge.bottom);
  }
  final edge = distances.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  final margin = kHomeInputDockRadius;
  final along = switch (edge) {
    DockEdge.left || DockEdge.right => (center.dy - bounds.top - margin) /
        (bounds.height - 2 * margin).clamp(1.0, double.infinity),
    DockEdge.top || DockEdge.bottom => (center.dx - bounds.left - margin) /
        (bounds.width - 2 * margin).clamp(1.0, double.infinity),
  };
  return (edge: edge, along: along.clamp(0.0, 1.0));
}

Offset clampDockCenterForDrag(Offset center, Rect bounds) {
  return Offset(
    center.dx.clamp(bounds.left, bounds.right),
    center.dy.clamp(bounds.top, bounds.bottom),
  );
}
