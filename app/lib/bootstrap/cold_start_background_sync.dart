import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/session_provider.dart';

/// 进主页后异步补全 deviceNo、事件目录与历史远端 sync（Splash 不得阻塞）。
///
/// 使用 [ProviderContainer] 而非 [WidgetRef]，避免 Hot Reload / 离页 dispose 后
/// 跨 await 的 `ref.read` 触发「ancestor lookup in dispose」断言。
class ColdStartBackgroundSync {
  ColdStartBackgroundSync._();

  static Future<void>? _inFlight;

  static Future<void> run(ProviderContainer container) {
    return _inFlight ??= _run(container).whenComplete(() => _inFlight = null);
  }

  static Future<void> _run(ProviderContainer container) async {
    final loggedIn = container.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      await container.read(eventCatalogProvider.notifier).bootstrap();
      return;
    }
    await container.read(deviceNoNotifierProvider.notifier).refresh();
    // 串行 HTTP，避免 iOS 同 host 连接槽与历史 WS 握手并行占满。
    await container.read(eventCatalogProvider.notifier).bootstrap();
    await container.read(homeHistoryProvider.notifier).refreshFromRemote();
    container.read(homeHistoryProvider.notifier).markInitialLoadComplete();
  }
}
