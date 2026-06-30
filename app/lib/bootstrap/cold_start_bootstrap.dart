import 'package:flutter/material.dart';

import '../config/env.dart';
import '../data/models.dart';
import '../session/session_controller.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_bootstrap_cache.dart';
import '../theme/theme_preset.dart';

class ColdStartResult {
  const ColdStartResult({
    required this.route,
    this.cachedSex,
    this.cachedBg,
    this.cachedPreset,
  });

  final String route;
  final BabySex? cachedSex;
  final Color? cachedBg;
  final ThemePreset? cachedPreset;
}

/// 冷启动：本地 restore、token 续期、主题缓存（在 Flutter Splash 页 await）。
class ColdStartBootstrap {
  ColdStartBootstrap._();

  static Future<ColdStartResult> run(SessionController session) async {
    await session.restore();
    await session.ensureFreshSession();
    final loaded = await Future.wait<Object?>([
      loadCachedBabySex(),
      loadThemePreferences(),
    ]);
    final themePrefs = loaded[1] as ThemePreferences;
    return ColdStartResult(
      route: AppEnv.postLoginRoute,
      cachedSex: loaded[0] as BabySex?,
      cachedBg: themePrefs.seed,
      cachedPreset: themePrefs.preset,
    );
  }
}
