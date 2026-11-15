import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import 'home_history_notifier.dart';

/// 旧回忆种子 prefs（硬删栈后忽略并清理）。
const kLegacyPredictionRecallSeedsPrefsKey = 'prediction_recall_seeds_v1';

/// 冷态骨架 mount nonce：进入预测页时刷新以重抽倒计时偏移。
final predictionDemoMountNonceProvider =
    StateProvider<int>((ref) => DateTime.now().microsecondsSinceEpoch);

/// 骨架锚点时刻：与 nonce 同批写入，秒 tick 只改显示不改 nextAt。
final predictionDemoMountNowProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// 统一历史池真喂养（供预测行 / lastAt）。
final predictionRealHistoryProvider = Provider<List<HistoryRecord>>((ref) {
  return ref.watch(homeHistoryProvider).items;
});

/// 删除遗留回忆种子 prefs（启动 / wipe 调用；忽略失败）。
Future<void> clearLegacyPredictionRecallSeedsPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLegacyPredictionRecallSeedsPrefsKey);
  } catch (_) {}
}
