import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_widget/home_widget_sync.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'cold_start_background_sync.dart';

/// 已登录 gateway HTTP bootstrap 门控：catalog/history sync + loadBaby 完成后再建历史 WS。
class GatewayBootstrapGate {
  GatewayBootstrapGate._();

  static Future<void>? _inFlight;
  static var _loggedInComplete = false;

  static bool get isLoggedInComplete => _loggedInComplete;

  static Future<void> ensureLoggedInComplete(WidgetRef ref) async {
    if (!ref.read(sessionProvider).isLoggedIn) return;
    if (_loggedInComplete) return;
    await (_inFlight ??= _run(ref).whenComplete(() => _inFlight = null));
  }

  static Future<void> _run(WidgetRef ref) async {
    await ColdStartBackgroundSync.run(ref);
    try {
      final baby = await ref.read(settingsRepositoryProvider).loadBaby();
      ref.read(babySexProvider.notifier).state = baby.sex;
      await persistCachedBabySex(baby.sex);
    } catch (_) {}
    await ensureWidgetReadyFromRef(ref);
    _loggedInComplete = true;
  }

  static void reset() {
    _loggedInComplete = false;
    _inFlight = null;
  }
}
