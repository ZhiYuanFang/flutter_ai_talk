import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_next_predictor.dart';
import '../data/smart_prediction_rows.dart';
import '../home_widget/widget_hero_skip_store.dart';
import '../home_widget/widget_row_builder.dart';
import '../home_widget/widget_tip_cache.dart';
import 'event_catalog_notifier.dart';
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

/// 智能预测页行列表：7 日 range ∪ 回忆种子；尊重推演关闭集合。
final smartPredictionRowsProvider = Provider<List<SmartPredictionRow>>((ref) {
  ref.watch(predictionRangeEnsureProvider);
  final history = ref.watch(predictionHistoryWithRecallSeedsProvider);
  final rangeItems = ref.watch(predictionRangeHistoryProvider).items;
  final homeItems = ref.watch(homeHistoryProvider).items;
  final catalog = ref.watch(eventCatalogProvider).items;
  final babyAsync = ref.watch(settingsBabyProvider);
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  final now = DateTime.now();
  final birth = babyAsync.asData?.value.birthDate ?? DateTime(now.year, 1, 1);
  // active 仅来自真历史（不含种子伪记录）
  final activeKeys = <String>{
    ...collectActiveTimingRows(rangeItems, catalog: catalog)
        .map((e) => e.eventId),
    ...collectActiveTimingRows(homeItems, catalog: catalog)
        .map((e) => e.eventId),
  }.where((e) => e.isNotEmpty).toSet();
  return buildSmartPredictionRows(
    history: history,
    catalog: catalog,
    now: now,
    birthDate: birth,
    disabledForecastIds: disabled,
    activeEventKeys: activeKeys,
  );
});

/// 全部可预测结果（未滤 skip；已滤推演关闭）。
final smartPredictionsProvider = Provider<List<EventNextPrediction>>((ref) {
  final rows = ref.watch(smartPredictionRowsProvider);
  return [
    for (final r in rows)
      if (r.prediction != null) r.prediction!,
  ];
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
