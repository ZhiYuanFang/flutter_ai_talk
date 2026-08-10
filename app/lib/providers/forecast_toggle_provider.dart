import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/forecast_toggle_store.dart';
import '../home_widget/home_widget_sync.dart';

/// 推演关闭的 eventId 集合（默认全开 → 空集）。
final forecastDisabledIdsProvider =
    AsyncNotifierProvider<ForecastDisabledIdsNotifier, Set<String>>(
  ForecastDisabledIdsNotifier.new,
);

class ForecastDisabledIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ForecastToggleStore.loadDisabledIds();

  /// 设置某事件推演开关并刷新状态；调度小组件同步。
  Future<void> setEnabled(String eventId, bool enabled) async {
    await ForecastToggleStore.setEnabled(eventId, enabled);
    state = AsyncData(await ForecastToggleStore.loadDisabledIds());
    // 桌面小组件与预测页共用关闭集合
    unawaited(scheduleHomeWidgetSync(ref));
  }
}
