import 'package:flutter/widgets.dart';

import '../ui/widgets/keyboard_input_bridge.dart';

/// 在路由进入/返回时清理焦点，避免页面被动弹出键盘。
class FocusCleanupNavigatorObserver extends NavigatorObserver {
  void _scheduleClearFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = FocusManager.instance.primaryFocus;
      if (focus != null && focus.hasFocus) {
        focus.unfocus();
      }
      keyboardInputBridgeController.detach();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _scheduleClearFocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _scheduleClearFocus();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _scheduleClearFocus();
  }
}
