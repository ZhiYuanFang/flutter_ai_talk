import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../api/app_debug_log.dart';
import '../data/models.dart';
import '../providers/home_history_notifier.dart';
import 'home_widget_constants.dart';
import 'home_widget_payload.dart';

Future<void>? _depthInFlight;

/// 后台预拉历史深度（single-flight）。
Future<void> ensureWidgetHistoryDepth(dynamic ref) {
  if (kIsWeb) return Future.value();
  return _depthInFlight ??= _ensureImpl(ref).whenComplete(() {
    _depthInFlight = null;
  });
}

bool historySpansEnoughDays(List<HistoryRecord> items, int days) {
  if (items.isEmpty) return false;
  final oldest = items.first.createdAt.toLocal();
  return DateTime.now().difference(oldest).inDays >= days;
}

Future<void> _ensureImpl(dynamic ref) async {
  if (await readWidgetHistoryDepthReady()) return;

  final notifier = ref.read(homeHistoryProvider.notifier);
  final deadline = DateTime.now().add(HomeWidgetConstants.prefetchTimeout);

  while (DateTime.now().isBefore(deadline)) {
    final state = ref.read(homeHistoryProvider);
    if (historySpansEnoughDays(state.items, HomeWidgetConstants.prefetchDaySpan)) {
      AppDebugLog.homeWidget('depth ready by days');
      await setWidgetHistoryDepthReady(true);
      return;
    }
    if (state.highestPageLoaded >= HomeWidgetConstants.maxPrefetchPages) {
      AppDebugLog.homeWidget('depth ready by pages');
      await setWidgetHistoryDepthReady(true);
      return;
    }
    if (!state.hasMore) {
      AppDebugLog.homeWidget('depth ready no more');
      await setWidgetHistoryDepthReady(true);
      return;
    }
    if (notifier.isLoadMoreCircuitOpen) {
      AppDebugLog.homeWidget('depth circuit open');
      await setWidgetHistoryDepthReady(true);
      return;
    }

    final ok = await notifier.loadNextHistoryPage();
    if (!ok) {
      AppDebugLog.homeWidget(
        'depth page fail consecutive=${notifier.consecutiveLoadMoreFailures}',
      );
      if (notifier.isLoadMoreCircuitOpen) {
        await setWidgetHistoryDepthReady(true);
        return;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  AppDebugLog.homeWidget('depth timeout fallback');
  await setWidgetHistoryDepthReady(true);
}
