import 'dart:ui';

/// 贴边吸附边。
enum DockEdge { top, bottom, left, right }

/// 默认贴边球直径（与历史输入模式球一致）。
const kDefaultEdgeDockDiameter = 48.0;

const kDefaultEdgeDockRadius = kDefaultEdgeDockDiameter / 2;

const kDefaultEdgeDockHitExpand = 24.0;

/// 松手时圆外缘进入该带则吸附为半圆。
const kDefaultEdgeDockSnapThreshold = 72.0;

/// 两球圆心最小额外间隙（互不重叠基线）。
const kDefaultEdgeDockGap = 8.0;

/// 历史别名（输入模式球 → 现预测竖屏语音球）。
const kHomeInputDockDiameter = kDefaultEdgeDockDiameter;
const kHomeInputDockRadius = kDefaultEdgeDockRadius;
const kPredictionVoiceDockDefaultEdge = DockEdge.left;
const kPredictionVoiceDockDefaultAlong = 0.85;
const kHomeInputDockDefaultEdge = kPredictionVoiceDockDefaultEdge;
const kHomeInputDockDefaultAlong = kPredictionVoiceDockDefaultAlong;
const kHomeInputDockSnapThreshold = kDefaultEdgeDockSnapThreshold;

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

/// 吸附态圆心（圆心在边缘线上，半圆在屏内）。
Offset dockCircleCenterForSnapped({
  required DockEdge edge,
  required double along,
  required Rect bounds,
  double diameter = kDefaultEdgeDockDiameter,
}) {
  final margin = diameter / 2;
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

/// 全圆圆心（相对半圆沿屏内法向内移一个半径）。
Offset dockCircleCenterForFullCircle({
  required DockEdge edge,
  required double along,
  required Rect bounds,
  double diameter = kDefaultEdgeDockDiameter,
}) {
  final r = diameter / 2;
  final semi = dockCircleCenterForSnapped(
    edge: edge,
    along: along,
    bounds: bounds,
    diameter: diameter,
  );
  return switch (edge) {
    DockEdge.left => semi + Offset(r, 0),
    DockEdge.right => semi + Offset(-r, 0),
    DockEdge.top => semi + Offset(0, r),
    DockEdge.bottom => semi + Offset(0, -r),
  };
}

({DockEdge edge, double along}) snapDockToNearestEdge(
  Offset center,
  Rect bounds, {
  bool allowTopBottom = true,
  double diameter = kDefaultEdgeDockDiameter,
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
  final margin = diameter / 2;
  final along = switch (edge) {
    DockEdge.left || DockEdge.right => (center.dy - bounds.top - margin) /
        (bounds.height - 2 * margin).clamp(1.0, double.infinity),
    DockEdge.top || DockEdge.bottom => (center.dx - bounds.left - margin) /
        (bounds.width - 2 * margin).clamp(1.0, double.infinity),
  };
  return (edge: edge, along: along.clamp(0.0, 1.0));
}

bool dockShouldSnapToEdge(
  Offset center,
  Rect bounds, {
  bool allowTopBottom = true,
  double diameter = kDefaultEdgeDockDiameter,
  double snapThreshold = kDefaultEdgeDockSnapThreshold,
}) {
  final r = diameter / 2;
  final nearLeft = center.dx - r <= bounds.left + snapThreshold;
  final nearRight = center.dx + r >= bounds.right - snapThreshold;
  if (!allowTopBottom) {
    return nearLeft || nearRight;
  }
  final nearTop = center.dy - r <= bounds.top + snapThreshold;
  final nearBottom = center.dy + r >= bounds.bottom - snapThreshold;
  return nearLeft || nearRight || nearTop || nearBottom;
}

Offset clampDockCenterForDrag(
  Offset center,
  Rect bounds, {
  double diameter = kDefaultEdgeDockDiameter,
}) {
  final margin = diameter / 2;
  return Offset(
    center.dx.clamp(bounds.left + margin, bounds.right - margin),
    center.dy.clamp(bounds.top + margin, bounds.bottom - margin),
  );
}

/// 两圆是否重叠（含最小间隙）。
bool dockCirclesOverlap(
  Offset a,
  Offset b, {
  double diameterA = kDefaultEdgeDockDiameter,
  double diameterB = kDefaultEdgeDockDiameter,
  double gap = kDefaultEdgeDockGap,
}) {
  final minDist = diameterA / 2 + diameterB / 2 + gap;
  return (a - b).distance < minDist;
}

/// 同边沿沿边方向满足不重叠的最小 along 步长。
double dockMinAlongSeparation({
  required DockEdge edge,
  required Rect bounds,
  double diameter = kDefaultEdgeDockDiameter,
  double gap = kDefaultEdgeDockGap,
}) {
  final margin = diameter / 2;
  final span = switch (edge) {
    DockEdge.left || DockEdge.right =>
      (bounds.height - 2 * margin).clamp(1.0, double.infinity),
    DockEdge.top || DockEdge.bottom =>
      (bounds.width - 2 * margin).clamp(1.0, double.infinity),
  };
  return ((diameter + gap) / span).clamp(0.0, 1.0);
}

/// 贴边半圆向屏内扩大的命中矩形（相对 bounds 坐标系）。
({double left, double top, double width, double height}) edgeDockHitTargetRect({
  required Offset center,
  required DockEdge edge,
  required bool fullCircleHit,
  double diameter = kDefaultEdgeDockDiameter,
  double hitExpand = kDefaultEdgeDockHitExpand,
}) {
  if (fullCircleHit) {
    final size = diameter + hitExpand * 2;
    return (
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
    );
  }
  final vertical = diameter + 16.0;
  final inner = diameter + hitExpand;
  return switch (edge) {
    DockEdge.right => (
        left: center.dx - inner,
        top: center.dy - vertical / 2,
        width: inner,
        height: vertical,
      ),
    DockEdge.left => (
        left: center.dx,
        top: center.dy - vertical / 2,
        width: inner,
        height: vertical,
      ),
    DockEdge.top => (
        left: center.dx - vertical / 2,
        top: center.dy,
        width: vertical,
        height: inner,
      ),
    DockEdge.bottom => (
        left: center.dx - vertical / 2,
        top: center.dy - inner,
        width: vertical,
        height: inner,
      ),
  };
}
