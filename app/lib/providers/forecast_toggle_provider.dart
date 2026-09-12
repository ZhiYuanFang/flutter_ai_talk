import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../config/forecast_toggle_store.dart';
import '../home_widget/home_widget_sync.dart';
import 'cash_vip_provider.dart';

/// 推演关闭的 eventId 集合（默认全开 → 空集）。
final forecastDisabledIdsProvider =
    AsyncNotifierProvider<ForecastDisabledIdsNotifier, Set<String>>(
  ForecastDisabledIdsNotifier.new,
);

class ForecastDisabledIdsNotifier extends AsyncNotifier<Set<String>> {
  /// 槽位对齐 single-flight。
  Future<void>? _alignInFlight;

  /// 写盘自触发：对齐引起的 rebuild 不得重入裁剪。
  var _alignIgnoreSelf = false;

  @override
  Future<Set<String>> build() => ForecastToggleStore.loadDisabledIds();

  /// 设置某事件推演开关并刷新状态；调度小组件同步。
  Future<void> setEnabled(String eventId, bool enabled) async {
    await ForecastToggleStore.setEnabled(eventId, enabled);
    state = AsyncData(await ForecastToggleStore.loadDisabledIds());
    // 桌面小组件与预测页共用关闭集合
    unawaited(scheduleHomeWidgetSync(ref));
  }

  /// 非 VIP 热态：开启数 > allowedCount 时关掉任意超额项；只关不补。
  /// [catalogReady] 为 false 时跳过，避免 catalog 未到时按 0 误关全量。
  Future<void> alignEnabledToAllowedCount({
    required List<String> enabledEventIds,
    required int allowedCount,
    required bool catalogReady,
  }) {
    if (_alignIgnoreSelf) return Future.value();
    if (!catalogReady) return Future.value();
    return _alignInFlight ??= _alignEnabledToAllowedCountImpl(
      enabledEventIds: enabledEventIds,
      allowedCount: allowedCount,
    ).whenComplete(() {
      _alignInFlight = null;
    });
  }

  Future<void> _alignEnabledToAllowedCountImpl({
    required List<String> enabledEventIds,
    required int allowedCount,
  }) async {
    // 先 settle VIP，避免 loading 瞬时当非 VIP 误裁。
    final isVip =
        (await ensureVipSettled(ref))?.isVip == true;
    if (isVip) return;
    // -1 历史全开哨兵：不裁。
    if (allowedCount < 0) return;
    final enabled = <String>{
      for (final raw in enabledEventIds)
        if (raw.trim().isNotEmpty) raw.trim(),
    }.toList()
      ..sort();
    // 已 ≤ N：幂等跳过（含加购后不自动开）。
    if (enabled.length <= allowedCount) return;
    final toDisable = enabled.skip(allowedCount).toList();
    AppDebugLog.featureUnlock(
      'forecast slot cap trim allowed=$allowedCount '
      'enabled=${enabled.length} disable=${toDisable.length}',
    );
    _alignIgnoreSelf = true;
    try {
      await ForecastToggleStore.disableMany(toDisable);
      state = AsyncData(await ForecastToggleStore.loadDisabledIds());
      unawaited(scheduleHomeWidgetSync(ref));
    } finally {
      _alignIgnoreSelf = false;
    }
  }
}
