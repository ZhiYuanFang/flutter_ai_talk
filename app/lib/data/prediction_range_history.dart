import '../api/app_debug_log.dart';
import 'feed_repository.dart';
import 'history_list_page.dart';
import 'history_mapper.dart';
import 'home_history_store.dart';
import 'models.dart';

/// 预测/小组件共用的近 7 日窗：本地 today-6d 00:00 → now（含 7 个自然日）。
const kPredictionRangeDaySpan = 7;

/// resume / 预测下拉增量窗时长。
const kHistoryRollingWindow = Duration(hours: 24);

/// 返回 (startUnixSec, endUnixSec)。
(int, int) predictionSevenDayUnixBounds([DateTime? now]) {
  final n = (now ?? DateTime.now()).toLocal();
  final startDay =
      DateTime(n.year, n.month, n.day).subtract(const Duration(days: 6));
  return (
    historyDateTimeToUnixSeconds(startDay),
    historyDateTimeToUnixSeconds(n),
  );
}

/// 滚动 24h 窗：`now−24h` → `now`（非自然日 00:00）。
(int, int) predictionRolling24hUnixBounds([DateTime? now]) {
  final n = (now ?? DateTime.now()).toLocal();
  final start = n.subtract(kHistoryRollingWindow);
  return (
    historyDateTimeToUnixSeconds(start),
    historyDateTimeToUnixSeconds(n),
  );
}

/// 拉取近 7 日全事件历史（升序）；失败返回 `null`。
///
/// **仅一次** `filter`（limit=500）；触顶截断，不再 `v2/list` 补页。
Future<List<HistoryRecord>?> fetchPredictionSevenDayHistory(
  FeedRepository feed, {
  DateTime? now,
}) async {
  final bounds = predictionSevenDayUnixBounds(now);
  final start = bounds.$1;
  final end = bounds.$2;

  final filtered = await feed.tryLoadHistoryFilter(
    startTime: start,
    endTime: end,
    limit: kHistoryFilterMaxLimit,
  );
  if (filtered == null) {
    AppDebugLog.homeWidget('history seed filter fail');
    return null;
  }

  if (filtered.length >= kHistoryFilterMaxLimit) {
    AppDebugLog.homeWidget(
      'history seed truncated count=${filtered.length} start=$start end=$end',
    );
  } else {
    AppDebugLog.homeWidget(
      'history seed ok count=${filtered.length} start=$start end=$end',
    );
  }
  return historyListToHomeAsc(filtered);
}

/// 拉取滚动 24h 全事件历史（升序）；失败返回 `null`。
Future<List<HistoryRecord>?> fetchPredictionRolling24hHistory(
  FeedRepository feed, {
  DateTime? now,
}) async {
  final bounds = predictionRolling24hUnixBounds(now);
  final start = bounds.$1;
  final end = bounds.$2;

  final filtered = await feed.tryLoadHistoryFilter(
    startTime: start,
    endTime: end,
    limit: kHistoryFilterMaxLimit,
  );
  if (filtered == null) {
    AppDebugLog.homeWidget('history rolling24h filter fail');
    return null;
  }
  AppDebugLog.homeWidget(
    'history rolling24h ok count=${filtered.length} start=$start end=$end',
  );
  return historyListToHomeAsc(filtered);
}
