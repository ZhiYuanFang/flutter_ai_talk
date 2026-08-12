import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_widget/home_widget_sync.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/settings_baby.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'cold_start_background_sync.dart';

/// 已登录 gateway HTTP bootstrap 门控：catalog/history sync + loadBaby 完成后再建历史 WS。
///
/// 入参为 [ProviderContainer]，可安全跨 await（不绑定已 dispose 的 Widget 元素）。
class GatewayBootstrapGate {
  GatewayBootstrapGate._();

  static Future<void>? _inFlight;
  static var _loggedInComplete = false;

  static bool get isLoggedInComplete => _loggedInComplete;

  static Future<void> ensureLoggedInComplete(ProviderContainer container) async {
    if (!container.read(sessionProvider).isLoggedIn) return;
    if (_loggedInComplete) return;
    await (_inFlight ??= _run(container).whenComplete(() => _inFlight = null));
  }

  static Future<void> _run(ProviderContainer container) async {
    await ColdStartBackgroundSync.run(container);
    try {
      final baby = await container.read(settingsRepositoryProvider).loadBaby();
      container.read(babySexProvider.notifier).state = baby.sex;
      await persistCachedBabySex(baby.sex);
      // 刷新展示用画像，避免冷启动抢跑缓存的空 id 占位残留。
      container.invalidate(settingsBabyProvider);
    } catch (_) {}
    await ensureWidgetReadyFromRef(container);
    _loggedInComplete = true;
  }

  static void reset() {
    _loggedInComplete = false;
    _inFlight = null;
  }
}
