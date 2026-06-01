import 'package:flutter/material.dart';

import 'keyboard_input_bridge.dart';

/// 点击空白区域时收起键盘（包裹 [MaterialApp] / [MaterialApp.router] 的 `child`）。
class KeyboardDismissScope extends StatelessWidget {
  const KeyboardDismissScope({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final scope = FocusScope.of(context);
        if (scope.hasFocus) {
          scope.unfocus();
        }
        keyboardInputBridgeController.detach();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
