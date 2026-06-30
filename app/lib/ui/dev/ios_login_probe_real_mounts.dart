import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/pangbao_transport_release.dart';
import '../../providers/event_catalog_notifier.dart';
import '../../providers/home_history_notifier.dart';
import '../../providers/repositories.dart';
import '../../ucg/providers/ucg_providers.dart';

/// 探针页挂载真实 Home Riverpod provider（与 fake transports 对照）。
class IosLoginProbeRealMounts {
  StreamSubscription<dynamic>? _feedSub;
  var _homeWatchActive = false;

  bool get homeWatchActive => _homeWatchActive;

  void mountFeedWatchLatest(WidgetRef ref) {
    final feed = ref.read(feedRepositoryProvider);
    _feedSub?.cancel();
    _feedSub = feed.watchLatest().listen((_) {});
    feed.ensureHistoryWebSocketConnected();
  }

  Future<void> mountUcgRepo(WidgetRef ref) async {
    await activateUcgHomeSession(ref, requireHomeMounted: false);
  }

  void startLogoDeferredUnawaited(WidgetRef ref) {
    unawaited(ref.read(eventCatalogProvider.notifier).runDeferredLogoDownloads());
  }

  void enableHomeProviderWatch() {
    _homeWatchActive = true;
  }

  /// 探针 build 中调用，复刻 Home `ref.watch(homeHistoryProvider)`。
  void watchHomeProvidersInBuild(WidgetRef ref) {
    if (!_homeWatchActive) return;
    ref.watch(homeHistoryProvider);
    ref.watch(eventCatalogProvider);
  }

  Future<void> release(WidgetRef ref) async {
    _homeWatchActive = false;
    await _feedSub?.cancel();
    _feedSub = null;
    await releasePangbaoHomeTransports(ref);
  }

  void dispose() {
    _homeWatchActive = false;
    unawaited(_feedSub?.cancel());
    _feedSub = null;
  }
}
