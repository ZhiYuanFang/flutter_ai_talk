import 'dart:ui';

/// 输入模式 dock 吸附边。
enum DockEdge { top, bottom, left, right }

/// 贴边半圆控件直径。
const kHomeInputDockDiameter = 48.0;

const kHomeInputDockRadius = kHomeInputDockDiameter / 2;

const kHomeInputDockDefaultEdge = DockEdge.right;

const kHomeInputDockDefaultAlong = 0.75;

/// 松手时圆的外缘进入该贴边吸附带则吸附为半圆，否则保持自由悬浮整圆。
const kHomeInputDockSnapThreshold = 72.0;

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

/// 全圆展示时圆心坐标（相对 [dockCircleCenterForSnapped] 沿屏内法向内移一个半径）。
Offset dockCircleCenterForFullCircle({
  required DockEdge edge,
  required double along,
  required Rect bounds,
}) {
  final semi = dockCircleCenterForSnapped(edge: edge, along: along, bounds: bounds);
  return switch (edge) {
    DockEdge.left => semi + const Offset(kHomeInputDockRadius, 0),
    DockEdge.right => semi + const Offset(-kHomeInputDockRadius, 0),
    DockEdge.top => semi + const Offset(0, kHomeInputDockRadius),
    DockEdge.bottom => semi + const Offset(0, -kHomeInputDockRadius),
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

/// 圆心到最近边的距离（像素）。
double dockMinDistanceToEdge(
  Offset center,
  Rect bounds, {
  bool allowTopBottom = true,
}) {
  final distances = <double>[
    (center.dy - bounds.top).abs(),
    (bounds.bottom - center.dy).abs(),
    (center.dx - bounds.left).abs(),
    (bounds.right - center.dx).abs(),
  ];
  if (!allowTopBottom) {
    return distances[2] < distances[3] ? distances[2] : distances[3];
  }
  return distances.reduce((a, b) => a < b ? a : b);
}

/// 是否应吸附到最近边（圆的外缘进入贴边吸附带）。
bool dockShouldSnapToEdge(
  Offset center,
  Rect bounds, {
  bool allowTopBottom = true,
}) {
  final r = kHomeInputDockRadius;
  final band = kHomeInputDockSnapThreshold;
  final nearLeft = center.dx - r <= bounds.left + band;
  final nearRight = center.dx + r >= bounds.right - band;
  if (!allowTopBottom) {
    return nearLeft || nearRight;
  }
  final nearTop = center.dy - r <= bounds.top + band;
  final nearBottom = center.dy + r >= bounds.bottom - band;
  return nearLeft || nearRight || nearTop || nearBottom;
}

/// 拖动时限制圆心，保证完整圆留在 [bounds] 内。
Offset clampDockCenterForDrag(Offset center, Rect bounds) {
  final margin = kHomeInputDockRadius;
  return Offset(
    center.dx.clamp(bounds.left + margin, bounds.right - margin),
    center.dy.clamp(bounds.top + margin, bounds.bottom - margin),
  );
}
