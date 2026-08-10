import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/prediction_recall_seed_store.dart';
import '../data/event_definition.dart';
import '../data/models.dart';
import '../data/prediction_recall_seed.dart';
import 'event_catalog_notifier.dart';
import 'forecast_toggle_provider.dart';
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
  }

  Future<void> clearSeeds(Iterable<String> rootIds) async {
    await PredictionRecallSeedStore.removeMany(rootIds);
    state = AsyncData(await PredictionRecallSeedStore.loadAll());
  }
}

/// 策略 B：range 已就绪且真历史完全为空，才允许量身定做。
final predictionRecallEmptyHistoryEligibleProvider = Provider<bool>((ref) {
  final range = ref.watch(predictionRangeHistoryProvider);
  if (!range.ready || range.loading) return false;
  return range.items.isEmpty;
});

/// 空库时的根事件队列（未关推演、无有效种子）；有任意真历史则恒为空。
final predictionRecallGapRootsProvider = Provider<List<EventDefinition>>((ref) {
  final eligible = ref.watch(predictionRecallEmptyHistoryEligibleProvider);
  if (!eligible) return const [];

  final catalog = ref.watch(eventCatalogProvider).items;
  final real = ref.watch(predictionRangeHistoryProvider).items;
  var seeds =
      ref.watch(predictionRecallSeedsProvider).asData?.value ?? const {};
  final drop = rootIdsWhoseRealHistoryCaughtUp(
    catalog: catalog,
    realHistory: real,
    seedRootIds: seeds.keys,
  );
  if (drop.isNotEmpty) {
    seeds = Map<String, PredictionRecallSeed>.from(seeds)
      ..removeWhere((k, _) => drop.contains(k));
    Future.microtask(() {
      ref.read(predictionRecallSeedsProvider.notifier).clearSeeds(drop);
    });
  }
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  return predictionRecallGapRoots(
    catalog: catalog,
    realHistory: real,
    seeds: seeds,
    disabledForecastIds: disabled,
  );
});

/// 供预测行使用的 merge 历史（真历史 ∪ 种子伪记录）。
final predictionHistoryWithRecallSeedsProvider =
    Provider<List<HistoryRecord>>((ref) {
  final catalog = ref.watch(eventCatalogProvider).items;
  final real = ref.watch(predictionRangeHistoryProvider).items;
  var seeds =
      ref.watch(predictionRecallSeedsProvider).asData?.value ?? const {};
  final drop = rootIdsWhoseRealHistoryCaughtUp(
    catalog: catalog,
    realHistory: real,
    seedRootIds: seeds.keys,
  );
  if (drop.isNotEmpty) {
    seeds = Map<String, PredictionRecallSeed>.from(seeds)
      ..removeWhere((k, _) => drop.contains(k));
    Future.microtask(() {
      ref.read(predictionRecallSeedsProvider.notifier).clearSeeds(drop);
    });
  }
  return mergeHistoryWithRecallSeeds(
    realHistory: real,
    catalog: catalog,
    seeds: seeds,
  );
});
