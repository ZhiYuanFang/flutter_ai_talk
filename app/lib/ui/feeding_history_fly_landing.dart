import 'package:flutter/material.dart';

import 'history_event_fly_landing.dart';
import 'home_history_scroll.dart';

/// 喂养页落点：历史行 [recordId] 的 EventLogo。
class FeedingHistoryFlyLanding implements HistoryEventFlyLanding {
  FeedingHistoryFlyLanding({
    required this.historyScrollKey,
    required this.recordId,
  });

  final GlobalKey<HomeHistoryScrollState> historyScrollKey;
  final String recordId;

  @override
  Future<bool> prepare() async {
    final scrollState = historyScrollKey.currentState;
    if (scrollState == null) return false;
    await scrollState.prepareFlyAnchorMeasure(recordId);
    return isAnchorVisible;
  }

  @override
  Offset? measureGlobalCenter() {
    return historyScrollKey.currentState?.measureAnchorCenterForRecord(recordId);
  }

  @override
  bool get isAnchorVisible {
    final scrollState = historyScrollKey.currentState;
    if (scrollState == null) return false;
    return scrollState.isFlyAnchorVisible(recordId);
  }
}
