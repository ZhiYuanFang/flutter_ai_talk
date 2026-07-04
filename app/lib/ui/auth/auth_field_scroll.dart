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
  scheduleKeyboardLift(
    context: context,
    focusNode: focusNode,
    anchorKey: anchorKey,
    scrollController: scrollController,
  );
}

/// 键盘 inset 变化后再次滚动当前聚焦的内联 auth 输入框。
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
    );
  });
}
