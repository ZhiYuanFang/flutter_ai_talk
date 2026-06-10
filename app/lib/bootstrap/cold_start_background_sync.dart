import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/session_provider.dart';

/// 进主页后异步补全 deviceNo、事件目录与历史远端 sync（Splash 不得阻塞）。
class ColdStartBackgroundSync {
  ColdStartBackgroundSync._();

  static Future<void>? _inFlight;

  static Future<void> run(WidgetRef ref) {
    return _inFlight ??= _run(ref).whenComplete(() => _inFlight = null);
  }

  static Future<void> _run(WidgetRef ref) async {
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      await ref.read(eventCatalogProvider.notifier).bootstrap();
      return;
    }
    await ref.read(deviceNoNotifierProvider.notifier).refresh();
    await Future.wait<void>([
      ref.read(eventCatalogProvider.notifier).bootstrap(),
      ref.read(homeHistoryProvider.notifier).refreshFromRemote(),
    ]);
    ref.read(homeHistoryProvider.notifier).markInitialLoadComplete();
  }
}
