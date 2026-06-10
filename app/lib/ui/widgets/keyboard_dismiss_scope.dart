import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'keyboard_input_bridge.dart';

/// 标记子树为键盘交互区：点击时不触发 [KeyboardDismissScope] 的外部收起。
class KeyboardDismissExclude extends StatelessWidget {
  const KeyboardDismissExclude({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _KeyboardDismissExcludeMarker(child: child);
  }
}

/// 点击空白区域时收起键盘（包裹 [MaterialApp] / [MaterialApp.router] 的 `child`）。
class KeyboardDismissScope extends StatefulWidget {
  const KeyboardDismissScope({required this.child, super.key});

  final Widget? child;

  @override
  State<KeyboardDismissScope> createState() => _KeyboardDismissScopeState();
}

class _KeyboardDismissScopeState extends State<KeyboardDismissScope> {
  /// pointerDown 在输入/浮层区内开始的手势，up 时不再按坐标 hit test（避免键盘顶起布局后误判）。
  final _pointerDownInsideExclude = <int>{};

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (!_shouldDismissKeyboardAt(event.position)) {
          _pointerDownInsideExclude.add(event.pointer);
        }
      },
      onPointerCancel: (event) {
        _pointerDownInsideExclude.remove(event.pointer);
      },
      onPointerUp: (event) {
        final startedInside = _pointerDownInsideExclude.remove(event.pointer);
        if (startedInside) return;
        if (keyboardInputBridgeController.shouldSuppressOutsideDismiss) return;
        if (!_shouldDismissKeyboardAt(event.position)) return;
        keyboardInputBridgeController.collapseInputChrome();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: widget.child,
    );
  }

  static bool _shouldDismissKeyboardAt(Offset globalPosition) {
    final result = HitTestResult();
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return false;
    WidgetsBinding.instance.hitTestInView(result, globalPosition, views.first.viewId);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) continue;
      if (target is RenderEditable) return false;
      if (_hasEditableAncestor(target)) return false;
      if (_hasKeyboardDismissExcludeAncestor(target)) return false;
    }
    return true;
  }

  static bool _hasEditableAncestor(RenderObject target) {
    var current = target.parent;
    while (current != null) {
      if (current is RenderEditable) return true;
      current = current.parent;
    }
    return false;
  }

  static bool _hasKeyboardDismissExcludeAncestor(RenderObject target) {
    var current = target.parent;
    while (current != null) {
      if (current is _RenderKeyboardDismissExclude) return true;
      current = current.parent;
    }
    return false;
  }
}

/// 供 hit test 识别：该子树属于键盘/输入交互区。
class _KeyboardDismissExcludeMarker extends SingleChildRenderObjectWidget {
  const _KeyboardDismissExcludeMarker({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderKeyboardDismissExclude();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderKeyboardDismissExclude renderObject,
  ) {}
}

class _RenderKeyboardDismissExclude extends RenderProxyBox {}

/// 与 [KeyboardDismissExclude] 相同语义，供浮层等需要 hit test 识别的场景。
Widget keyboardDismissExclude({required Widget child}) {
  return KeyboardDismissExclude(child: child);
}
