import 'package:flutter/material.dart';

import 'keyboard_dismiss_scope.dart';
import 'keyboard_input_bridge.dart';

/// 输入框底边与键盘（或浮层）顶边之间的间距。
const kKeyboardLiftGap = 5.0;

const _inlineAuthLiftDeltaSkipThreshold = 2.0;

final _lastTapGlobalByFocus = <FocusNode, Offset>{};

FocusNode? _inlineAuthLiftSessionFocus;
double _inlineAuthLiftLastInsetBucket = -1;
double _inlineAuthLiftLastScrollTarget = double.nan;
bool _inlineAuthInsetRetryPending = false;

bool _isInlineAuthLift({
  required ScrollController? scrollController,
  required double keyboardOverlayChrome,
  required bool inlineAuth,
}) =>
    inlineAuth && scrollController != null && keyboardOverlayChrome <= 0;

void _syncInlineAuthLiftSession(FocusNode focusNode) {
  if (_inlineAuthLiftSessionFocus != focusNode) {
    _inlineAuthLiftSessionFocus = focusNode;
    _inlineAuthLiftLastInsetBucket = -1;
    _inlineAuthLiftLastScrollTarget = double.nan;
  }
}

double _insetBucket(double inset) => (inset / 8).floorToDouble() * 8;

/// 记录用户点击输入区域时的全局坐标（在锚点组件内 hit test 精确定位子组件）。
void noteKeyboardLiftTap(FocusNode focusNode, Offset globalPosition) {
  _lastTapGlobalByFocus[focusNode] = globalPosition;
}

void clearKeyboardLiftTap(FocusNode focusNode) {
  _lastTapGlobalByFocus.remove(focusNode);
}

/// 包裹可编辑目标：记录点击坐标，并用 [anchorKey] 标记顶起锚点组件。
Widget keyboardLiftTarget({
  required FocusNode focusNode,
  required GlobalKey anchorKey,
  required Widget child,
}) {
  return KeyboardDismissExclude(
    child: Listener(
      onPointerDown: (event) => noteKeyboardLiftTap(focusNode, event.position),
      child: KeyedSubtree(key: anchorKey, child: child),
    ),
  );
}

RenderBox? resolveKeyboardLiftRenderBox({
  required FocusNode focusNode,
  GlobalKey? anchorKey,
}) {
  final anchorContext = anchorKey?.currentContext;
  final anchorBox = anchorContext?.findRenderObject();
  if (anchorBox is RenderBox && anchorBox.hasSize) {
    // 始终用 anchor 组件（如整颗 TextField）的外框底边，避免 hit 到
    // RenderEditable 等子节点导致底边偏小、滚动不足。
    return anchorBox;
  }

  final focusContext = focusNode.context;
  final focusBox = focusContext?.findRenderObject();
  if (focusBox is RenderBox && focusBox.hasSize) return focusBox;
  return null;
}

double renderBoxGlobalBottom(RenderBox box) {
  return box.localToGlobal(Offset.zero).dy + box.size.height;
}

/// 将 [targetBox] 底边滚到键盘（及可选浮层）上方 [kKeyboardLiftGap] 处。
void scrollKeyboardLiftTarget({
  required BuildContext context,
  required RenderBox targetBox,
  ScrollController? scrollController,
  BuildContext? ensureVisibleContext,
  double keyboardOverlayChrome = 0,
  bool inlineAuth = false,
  FocusNode? inlineAuthFocusNode,
}) {
  final mq = MediaQuery.of(context);
  final keyboardInset = mq.viewInsets.bottom;
  if (keyboardInset <= 0 && keyboardOverlayChrome <= 0) return;

  final liftLine = mq.size.height -
      keyboardInset -
      keyboardOverlayChrome -
      mq.padding.bottom -
      kKeyboardLiftGap;
  final targetBottom = renderBoxGlobalBottom(targetBox);
  if (targetBottom <= liftLine) return;

  final delta = targetBottom - liftLine;
  final controller = scrollController ?? Scrollable.maybeOf(context)?.widget.controller;
  if (controller != null && controller.hasClients) {
    final position = controller.position;
    final next = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
    if ((next - position.pixels).abs() < _inlineAuthLiftDeltaSkipThreshold) return;

    final useInlineAuthGuard = _isInlineAuthLift(
      scrollController: scrollController,
      keyboardOverlayChrome: keyboardOverlayChrome,
      inlineAuth: inlineAuth,
    );
    if (useInlineAuthGuard && inlineAuthFocusNode != null) {
      _syncInlineAuthLiftSession(inlineAuthFocusNode);
      final insetBucket = _insetBucket(keyboardInset);
      if (insetBucket == _inlineAuthLiftLastInsetBucket &&
          ! _inlineAuthLiftLastScrollTarget.isNaN &&
          (next - _inlineAuthLiftLastScrollTarget).abs() < _inlineAuthLiftDeltaSkipThreshold) {
        return;
      }
      _inlineAuthLiftLastInsetBucket = insetBucket;
      _inlineAuthLiftLastScrollTarget = next;
      if (position.isScrollingNotifier.value) {
        position.jumpTo(next);
      } else {
        controller.animateTo(
          next,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    controller.animateTo(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    return;
  }

  final fallbackContext = ensureVisibleContext;
  if (fallbackContext != null && fallbackContext.mounted) {
    Scrollable.ensureVisible(
      fallbackContext,
      alignment: 1,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

/// 聚焦后将顶起目标滚到键盘上方（全局统一：锚点底边 + [kKeyboardLiftGap]）。
void performKeyboardLift({
  required BuildContext context,
  required FocusNode focusNode,
  GlobalKey? anchorKey,
  ScrollController? scrollController,
  double keyboardOverlayChrome = 0,
  bool allowInsetRetry = false,
  bool inlineAuth = false,
}) {
  if (!focusNode.hasFocus) return;

  final useInlineAuth = _isInlineAuthLift(
    scrollController: scrollController,
    keyboardOverlayChrome: keyboardOverlayChrome,
    inlineAuth: inlineAuth,
  );
  if (useInlineAuth) {
    _syncInlineAuthLiftSession(focusNode);
  }

  void lift({required bool retryInsets}) {
    if (!focusNode.hasFocus) return;
    final liftContext = focusNode.context ?? context;
    if (!liftContext.mounted) return;
    final mq = MediaQuery.of(liftContext);
    final keyboardInset = mq.viewInsets.bottom;
    if (keyboardInset <= 0 && keyboardOverlayChrome <= 0) {
      if (retryInsets) {
        if (useInlineAuth) {
          if (!_inlineAuthInsetRetryPending) {
            _inlineAuthInsetRetryPending = true;
            Future<void>.delayed(const Duration(milliseconds: 50), () {
              _inlineAuthInsetRetryPending = false;
              lift(retryInsets: false);
            });
          }
        } else {
          Future<void>.delayed(const Duration(milliseconds: 50), () => lift(retryInsets: true));
          Future<void>.delayed(const Duration(milliseconds: 150), () => lift(retryInsets: true));
          Future<void>.delayed(const Duration(milliseconds: 300), () => lift(retryInsets: false));
        }
      }
      return;
    }

    final targetBox = resolveKeyboardLiftRenderBox(
      focusNode: focusNode,
      anchorKey: anchorKey,
    );
    if (targetBox == null) return;

    scrollKeyboardLiftTarget(
      context: liftContext,
      targetBox: targetBox,
      scrollController: scrollController,
      ensureVisibleContext: anchorKey?.currentContext ?? focusNode.context,
      keyboardOverlayChrome: keyboardOverlayChrome,
      inlineAuth: inlineAuth,
      inlineAuthFocusNode: focusNode,
    );
  }

  lift(retryInsets: allowInsetRetry);
}

/// 固定标题 + 底部 dock 布局：仅当绑定输入框的系统键盘弹出时，为 dock 增加 bottom padding。
double readKeyboardDockBottomPadding(
  BuildContext context, {
  required TextEditingController controller,
}) {
  final bridge = keyboardInputBridgeController;
  if (bridge.binding?.controller != controller) return 0;
  final raw = readRawViewInsetBottom(context);
  if (raw <= 0) return 0;
  if (bridge.isEmojiPanelDisplayed(raw)) return 0;
  return raw;
}

/// 包裹页面内输入 dock：键盘仅顶起 dock（含输入框与 emoji 面板），不顶标题栏。
Widget keyboardDockBottomInset({
  required TextEditingController controller,
  required Widget child,
}) {
  return AnimatedBuilder(
    animation: keyboardInputBridgeController,
    builder: (context, _) {
      final pad = readKeyboardDockBottomPadding(context, controller: controller);
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: pad),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: child,
      );
    },
  );
}

void scheduleKeyboardLift({
  required BuildContext context,
  required FocusNode focusNode,
  GlobalKey? anchorKey,
  ScrollController? scrollController,
  double keyboardOverlayChrome = 0,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    performKeyboardLift(
      context: context,
      focusNode: focusNode,
      anchorKey: anchorKey,
      scrollController: scrollController,
      keyboardOverlayChrome: keyboardOverlayChrome,
      allowInsetRetry: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performKeyboardLift(
        context: context,
        focusNode: focusNode,
        anchorKey: anchorKey,
        scrollController: scrollController,
        keyboardOverlayChrome: keyboardOverlayChrome,
        allowInsetRetry: true,
      );
    });
  });
}

/// 内联 auth 页聚焦顶起：单层 postFrame，带 inline 幂等 guard。
void scheduleInlineAuthKeyboardLift({
  required BuildContext context,
  required FocusNode focusNode,
  GlobalKey? anchorKey,
  ScrollController? scrollController,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    performKeyboardLift(
      context: context,
      focusNode: focusNode,
      anchorKey: anchorKey,
      scrollController: scrollController,
      allowInsetRetry: true,
      inlineAuth: true,
    );
  });
}
