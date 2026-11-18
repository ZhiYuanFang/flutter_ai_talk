import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_model_report_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/prediction_recall_provider.dart';
import '../providers/session_provider.dart';

/// 进主页后异步补全 deviceNo、事件目录与历史远端 sync（Splash 不得阻塞）。
///
/// 使用 [ProviderContainer] 而非 [WidgetRef]，避免 Hot Reload / 离页 dispose 后
/// 跨 await 的 `ref.read` 触发「ancestor lookup in dispose」断言。
class ColdStartBackgroundSync {
  ColdStartBackgroundSync._();

  static Future<void>? _inFlight;
  /// 最近一次成功完成历史 7 日种子的时刻（短窗内跳过二次种子）。
  static DateTime? _lastHistorySeedOkAt;

  static Future<void> run(ProviderContainer container) {
    return _inFlight ??= _run(container).whenComplete(() => _inFlight = null);
  }

  static Future<void> _run(ProviderContainer container) async {
    // 忽略旧回忆种子 prefs（间隔栈已硬删）
    unawaited(clearLegacyPredictionRecallSeedsPrefs());
    final loggedIn = container.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      await container.read(eventCatalogProvider.notifier).bootstrap();
      return;
    }
    await container.read(deviceNoNotifierProvider.notifier).refresh();
    // 设备型号上报：与目录/历史并行，不占串行槽（内部自有节流）。
    unawaited(syncDeviceModelReport(container));
    // 串行 HTTP，避免 iOS 同 host 连接槽与历史 WS 握手并行占满。
    await container.read(eventCatalogProvider.notifier).bootstrap();
    // Gateway 刚成功种子后，HomeScreen/二次 run 60s 内跳过历史，仅补目录
    final lastOk = _lastHistorySeedOkAt;
    if (lastOk != null &&
        DateTime.now().difference(lastOk) < const Duration(seconds: 60)) {
      container.read(homeHistoryProvider.notifier).markInitialLoadComplete();
      return;
    }
    // 磁盘若已有多页：保留深度，避免首次远程砍成 page1-only
    final ok = await container
        .read(homeHistoryProvider.notifier)
        .refreshFromRemote(preserveLoadedDepth: true);
    if (ok) {
      _lastHistorySeedOkAt = DateTime.now();
    }
    container.read(homeHistoryProvider.notifier).markInitialLoadComplete();
  }
}
