import 'package:flutter/material.dart';

/// 全局路由观察者：主壳竖屏语音感知「被上层 **PageRoute** 盖住」。
///
/// 必须用 [PageRoute] 而非 [ModalRoute]：后者会把 bottom sheet / dialog
///（PopupRoute）也算进 didPushNext，导致误 teardown + KWS 冷启。
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
