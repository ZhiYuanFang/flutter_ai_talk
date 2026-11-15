import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_next_predictor.dart';
import '../data/smart_prediction_rows.dart';
import '../home_widget/widget_hero_skip_store.dart';
import '../home_widget/widget_row_builder.dart';
import '../home_widget/widget_tip_cache.dart';
import 'appointment_last_occurrence_provider.dart';
import 'appointment_next_provider.dart';
import 'event_catalog_notifier.dart';
import 'event_last_at_provider.dart';
import 'forecast_toggle_provider.dart';
import 'home_history_notifier.dart';
import 'prediction_range_history_provider.dart';
import 'prediction_recall_provider.dart';
import 'settings_baby.dart';
import 'widget_tip_display_epoch_provider.dart';

/// 每秒滴答，驱动倒计时文案刷新（本地轻量）。
final predictionClockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now())
      .map((_) => DateTime.now());
});

/// 预测页行 + pending 全量（一次构建）。
final smartPredictionBundleProvider =
    Provider<SmartPredictionBuildResult>((ref) {
  ref.watch(predictionRangeEnsureProvider);
  final history = ref.watch(predictionRealHistoryProvider);
  final catalog = ref.watch(eventCatalogProvider).items;
  // 真历史变化时 max 刷新 tip 缓存（与组行同帧调度）
  scheduleEventLastAtObserveFromHistory(ref, history, catalog);
  final babyAsync = ref.watch(settingsBabyProvider);
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  final appointmentNext = ref.watch(appointmentNextCacheProvider);
  final appointmentLast = ref.watch(appointmentLastCacheProvider);
  final lastAtCache =
      ref.watch(eventLastAtCacheProvider).asData?.value ??
          const <String, DateTime>{};
  final now = DateTime.now();
  final birth = babyAsync.asData?.value.birthDate ?? DateTime(now.year, 1, 1);
  // active 仅来自统一池真历史
  final activeKeys = <String>{
    ...collectActiveTimingRows(history, catalog: catalog).map((e) => e.eventId),
  }.where((e) => e.isNotEmpty).toSet();
  return buildSmartPredictionBundle(
    history: history,
    catalog: catalog,
    now: now,
    birthDate: birth,
    disabledForecastIds: disabled,
    activeEventKeys: activeKeys,
    appointmentNextAtSecByRoot: {
      for (final e in appointmentNext.entries) e.key: e.value.nextAtSec,
    },
    lastAtCacheByRoot: lastAtCache,
    appointmentLastAtByRoot: {
      for (final e in appointmentLast.entries) e.key: e.value.at,
    },
    appointmentLastRemarkByRoot: {
      for (final e in appointmentLast.entries) e.key: e.value.remark,
    },
  );
});

/// 智能预测页行列表：真历史亲和预测；尊重推演关闭集合。
final smartPredictionRowsProvider = Provider<List<SmartPredictionRow>>((ref) {
  return ref.watch(smartPredictionBundleProvider).rows;
});

/// 卡上展示的预测（每根胜出一条；用于 tip / 小组件 hero 近邻）。
final smartPredictionsProvider = Provider<List<EventNextPrediction>>((ref) {
  final rows = ref.watch(smartPredictionRowsProvider);
  return [
    for (final r in rows)
      if (r.prediction != null) r.prediction!,
  ];
});

/// imminent pending：非合并含全部子预测（与卡一对一根不同）。
final smartPendingPredictionsProvider =
    Provider<List<EventNextPrediction>>((ref) {
  return ref.watch(smartPredictionBundleProvider).pendingPredictions;
});

/// 喂养顶栏：最近下一步（滤 skip + 推演关）。
final homePredictionTipProvider =
    FutureProvider<EventNextPrediction?>((ref) async {
  await ref.watch(predictionRangeEnsureProvider.future);
  final predictions = ref.watch(smartPredictionsProvider);
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  final skipped =
      await WidgetHeroSkipStore.reconcileAndActiveIds(predictions);
  return pickNearestPrediction(
    predictions: predictions,
    disabledForecastIds: disabled,
    skippedIds: skipped,
  );
});

/// 预测页底：小组件 tip trim 文案；无可展示正文时为 null（底栏隐藏）。
final widgetTipCardTextProvider = FutureProvider<String?>((ref) async {
  ref.watch(homeHistoryProvider);
  // sync 写 tip 后 bump，驱动重 peek
  ref.watch(widgetTipDisplayEpochProvider);
  return peekWidgetTipDisplayText();
});
