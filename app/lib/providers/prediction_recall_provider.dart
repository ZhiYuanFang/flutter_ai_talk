import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/prediction_recall_seed_store.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import '../data/prediction_recall_seed.dart';
import '../data/smart_prediction_rows.dart';
import '../home_widget/home_widget_sync.dart';
import 'event_catalog_notifier.dart';
import 'forecast_toggle_provider.dart';
import 'home_history_notifier.dart';
import 'predict_imminent_sync_provider.dart';
import 'prediction_range_history_provider.dart';

/// 本会话是否已点收尾 CTA（关闭引导层；再出现缺口时重置）。
final predictionRecallFinaleDismissedProvider = StateProvider<bool>((ref) => false);

/// 量身定做会话进行中（含思考/收尾，避免种子写完后缺口变空卸掉面板）。
final predictionRecallSessionActiveProvider = StateProvider<bool>((ref) => false);

/// Dialog 是否可见（软关后为 false，会话仍可 active，供再弹）。
final predictionRecallDialogVisibleProvider = StateProvider<bool>((ref) => false);

/// 冷态骨架 mount nonce：进入预测页时刷新以重抽倒计时偏移。
final predictionDemoMountNonceProvider =
    StateProvider<int>((ref) => DateTime.now().microsecondsSinceEpoch);

/// 骨架锚点时刻：与 nonce 同批写入，秒 tick 只改显示不改 nextAt。
final predictionDemoMountNowProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// 本会话卡片队列快照。
final predictionRecallSessionRootsProvider =
    StateProvider<List<EventDefinition>>((ref) => const []);

/// 本地回忆种子 map。
final predictionRecallSeedsProvider = AsyncNotifierProvider<
    PredictionRecallSeedsNotifier, Map<String, PredictionRecallSeed>>(
  PredictionRecallSeedsNotifier.new,
);

class PredictionRecallSeedsNotifier
    extends AsyncNotifier<Map<String, PredictionRecallSeed>> {
  @override
  Future<Map<String, PredictionRecallSeed>> build() async {
    return PredictionRecallSeedStore.loadAll();
  }

  Future<void> upsertSeed(PredictionRecallSeed seed) async {
    await PredictionRecallSeedStore.upsert(seed);
    state = AsyncData(await PredictionRecallSeedStore.loadAll());
    // 下一 turn 推桌面，与预测页间隔旁路对齐（单飞/延迟见 scheduleHomeWidgetSync）
    unawaited(scheduleHomeWidgetSync(ref));
    // 本机改喂养间隔后同步预测临近 pending（延迟读见 request 实现）
    unawaited(requestPredictImminentPendingSync(ref));
  }

  Future<void> clearSeeds(Iterable<String> rootIds) async {
    await PredictionRecallSeedStore.removeMany(rootIds);
    state = AsyncData(await PredictionRecallSeedStore.loadAll());
    unawaited(scheduleHomeWidgetSync(ref));
    // 自动清种子不推 pending：多由拉数/历史达标触发，避免误刷
  }
}

/// 策略 B：range 已就绪且真历史完全为空，才允许量身定做。
final predictionRecallEmptyHistoryEligibleProvider = Provider<bool>((ref) {
  final range = ref.watch(predictionRangeHistoryProvider);
  if (!range.ready || range.loading) return false;
  return range.items.isEmpty;
});

/// home∪range 真喂养（供预测行 / lastAt / 间隔旁路门闸）。
final predictionRealHistoryProvider = Provider<List<HistoryRecord>>((ref) {
  final rangeItems = ref.watch(predictionRangeHistoryProvider).items;
  final homeItems = ref.watch(homeHistoryProvider).items;
  return mergeRealHistoryById(rangeItems: rangeItems, homeItems: homeItems);
});

/// 清洗后的种子 map：丢弃已达标或真记录已空的根，并异步持久化清除。
final predictionRecallSeedsActiveProvider =
    Provider<Map<String, PredictionRecallSeed>>((ref) {
  final catalog = ref.watch(eventCatalogProvider).items;
  final real = ref.watch(predictionRealHistoryProvider);
  var seeds =
      ref.watch(predictionRecallSeedsProvider).asData?.value ?? const {};
  final drop = <String>{
    ...rootIdsWhoseRealHistoryCaughtUp(
      catalog: catalog,
      realHistory: real,
      seedRootIds: seeds.keys,
    ),
    ...rootIdsWhoseRealHistoryIsEmpty(
      catalog: catalog,
      realHistory: real,
      seedRootIds: seeds.keys,
    ),
  };
  if (drop.isNotEmpty) {
    seeds = Map<String, PredictionRecallSeed>.from(seeds)
      ..removeWhere((k, _) => drop.contains(k));
    Future.microtask(() {
      ref.read(predictionRecallSeedsProvider.notifier).clearSeeds(drop);
    });
  }
  return seeds;
});

/// rootId → 间隔旁路（仅未达标根会用到）。
final predictionRecallIntervalsProvider = Provider<Map<String, Duration>>((ref) {
  final seeds = ref.watch(predictionRecallSeedsActiveProvider);
  return {
    for (final e in seeds.entries)
      if (e.value.interval >= kMinIntervalForPrediction)
        e.key: e.value.interval,
  };
});

/// 空库时的根事件队列（未关推演、无有效种子）；有任意真历史则恒为空。
final predictionRecallGapRootsProvider = Provider<List<EventDefinition>>((ref) {
  final eligible = ref.watch(predictionRecallEmptyHistoryEligibleProvider);
  if (!eligible) return const [];

  final catalog = ref.watch(eventCatalogProvider).items;
  final real = ref.watch(predictionRealHistoryProvider);
  final seeds = ref.watch(predictionRecallSeedsActiveProvider);
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  return predictionRecallGapRoots(
    catalog: catalog,
    realHistory: real,
    seeds: seeds,
    disabledForecastIds: disabled,
  );
});

/// 兼容旧名：现为真喂养直通（不再 merge 伪记录）。
final predictionHistoryWithRecallSeedsProvider =
    Provider<List<HistoryRecord>>((ref) {
  return ref.watch(predictionRealHistoryProvider);
});
