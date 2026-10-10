import 'package:flutter/material.dart';

/// 全局路由观察者：主壳竖屏语音等需感知「被上层路由盖住」。
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
