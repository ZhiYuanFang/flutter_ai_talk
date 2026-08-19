import 'package:flutter/material.dart';

import '../widgets/keyboard_lift.dart';

/// 撑满视口以便贴底布局；键盘弹出时也保持，避免布局突变导致顶起错位。
double inlineAuthScrollMinHeight({
  required double viewportHeight,
  required double keyboardInset,
}) {
  return viewportHeight;
}

/// 内联 auth 输入：以点击锚点组件底边 + [kKeyboardLiftGap] 顶到键盘上方。
void scrollInlineAuthFieldIntoView(
  FocusNode focusNode, {
  required BuildContext context,
  ScrollController? scrollController,
  GlobalKey? anchorKey,
}) {
  scheduleInlineAuthKeyboardLift(
    context: context,
    focusNode: focusNode,
    anchorKey: anchorKey,
    scrollController: scrollController,
  );
}

/// 键盘 inset 变化后再次滚动当前聚焦的内联 auth 输入框。
///
/// 仅供 UCG compose 等非 auth 贴底页在 build 外显式调用；auth 页 MUST 使用 [InlineAuthKeyboardLiftHost]。
void scheduleInlineAuthScrollOnInset(
  BuildContext context, {
  required FocusNode? focusedNode,
  ScrollController? scrollController,
  GlobalKey? anchorKey,
  double keyboardOverlayChrome = 0,
}) {
  if (focusedNode == null || !focusedNode.hasFocus) return;
  if (MediaQuery.viewInsetsOf(context).bottom <= 0 && keyboardOverlayChrome <= 0) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    performKeyboardLift(
      context: context,
      focusNode: focusedNode,
      anchorKey: anchorKey,
      scrollController: scrollController,
      keyboardOverlayChrome: keyboardOverlayChrome,
      allowInsetRetry: true,
      inlineAuth: keyboardOverlayChrome <= 0 && scrollController != null,
    );
  });
}

/// 监听系统 metrics / inset 变化，在 auth 页键盘弹出周期内幂等调度顶起。
///
/// MUST NOT 在 [build] 内注册 postFrameCallback；由本 Host 在 [didChangeMetrics] 中调度。
class InlineAuthKeyboardLiftHost extends StatefulWidget {
  const InlineAuthKeyboardLiftHost({
    super.key,
    required this.scrollController,
    required this.focusedNode,
    required this.anchorKey,
    required this.child,
  });

  final ScrollController scrollController;
  final FocusNode? focusedNode;
  final GlobalKey? anchorKey;
  final Widget child;

  @override
  State<InlineAuthKeyboardLiftHost> createState() => _InlineAuthKeyboardLiftHostState();
}

class _InlineAuthKeyboardLiftHostState extends State<InlineAuthKeyboardLiftHost> with WidgetsBindingObserver {
  double _lastInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _onInsetsMaybeChanged();
  }

  void _onInsetsMaybeChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inset = MediaQuery.viewInsetsOf(context).bottom;
      if ((inset - _lastInset).abs() < 1.0) return;

      final wasOpen = _lastInset > 0;
      _lastInset = inset;

      if (inset <= 0) {
        if (wasOpen && widget.scrollController.hasClients) {
          final pixels = widget.scrollController.position.pixels;
          if (pixels > 0) {
            widget.scrollController.jumpTo(0);
          }
        }
        return;
      }

      final node = widget.focusedNode;
      if (node == null || !node.hasFocus) return;

      performKeyboardLift(
        context: context,
        focusNode: node,
        anchorKey: widget.anchorKey,
        scrollController: widget.scrollController,
        inlineAuth: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
