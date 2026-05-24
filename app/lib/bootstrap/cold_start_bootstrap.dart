import 'package:flutter/material.dart';

import '../data/models.dart';
import '../session/session_controller.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_bootstrap_cache.dart';

class ColdStartResult {
  const ColdStartResult({
    required this.route,
    this.cachedSex,
    this.cachedBg,
  });

  final String route;
  final BabySex? cachedSex;
  final Color? cachedBg;
}

/// 冷启动：本地 restore、token 续期、主题缓存（在 Flutter Splash 页 await）。
class ColdStartBootstrap {
  ColdStartBootstrap._();

  static Future<ColdStartResult> run(SessionController session) async {
    await session.restore();
    await session.ensureFreshSession();
    final loaded = await Future.wait<Object?>([
      loadCachedBabySex(),
      loadCustomBackground(),
    ]);
    return ColdStartResult(
      route: session.isLoggedIn ? '/home' : '/login',
      cachedSex: loaded[0] as BabySex?,
      cachedBg: loaded[1] as Color?,
    );
  }
}
