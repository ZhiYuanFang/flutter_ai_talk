import 'package:flutter/material.dart';

/// 历史落库飞入落点：页面只负责滚入可视与测锚，动画轨迹由共享 Overlay 负责。
abstract class HistoryEventFlyLanding {
  /// 飞入前准备（滚到锚点等）；失败则不应开启动画。
  Future<bool> prepare();

  /// 落点全局中心；不可用时返回 null（调用方 MUST 不飞）。
  Offset? measureGlobalCenter();

  /// 锚点是否在约定可视区内；默认以 measure 非空为准。
  bool get isAnchorVisible {
    final c = measureGlobalCenter();
    return c != null && c.dx.isFinite && c.dy.isFinite;
  }
}

/// 从 [GlobalKey] 测 RenderBox 全局中心。
Offset? measureGlobalCenterForKey(GlobalKey? key) {
  final context = key?.currentContext;
  if (context == null) return null;
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.attached || !box.hasSize) return null;
  if (box.size.width < 1 || box.size.height < 1) return null;
  final center = box.localToGlobal(box.size.center(Offset.zero));
  if (!center.dx.isFinite || !center.dy.isFinite || center == Offset.zero) {
    return null;
  }
  return center;
}
