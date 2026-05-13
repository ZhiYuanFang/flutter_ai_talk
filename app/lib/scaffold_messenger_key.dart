import 'package:flutter/material.dart';

/// 与 [MaterialApp.router] 的 `scaffoldMessengerKey` 绑定，便于在子路由关闭后仍展示 SnackBar。
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
