import '../api/app_debug_log.dart';
import 'feed_repository.dart';
import 'history_list_page.dart';
import 'history_mapper.dart';
import 'home_history_store.dart';
import 'models.dart';

/// 预测/小组件共用的近 7 日窗：本地 today-6d 00:00 → now（含 7 个自然日）。
const kPredictionRangeDaySpan = 7;

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

/// 拉取近 7 日全事件历史（升序）；失败返回 `null`。
///
/// 先 `filter`（limit=500）；触顶后再用 `v2/list` 同窗分页补全。
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
    AppDebugLog.homeWidget('range filter fail');
    return null;
  }

  if (filtered.length < kHistoryFilterMaxLimit) {
    AppDebugLog.homeWidget(
      'range filter ok count=${filtered.length} start=$start end=$end',
    );
    return historyListToHomeAsc(filtered);
  }

  AppDebugLog.homeWidget('range filter truncated=${filtered.length}, v2 pages');
  final byId = <String, HistoryRecord>{
    for (final r in filtered) r.id: r,
  };
  var page = 1;
  const pageSize = 100;
  var consecutiveFails = 0;

  while (page <= 40) {
    final chunk = await feed.tryLoadHistoryPageV2(
      page: page,
      pageSize: pageSize,
      startTime: start,
      endTime: end,
    );
    if (chunk == null) {
      consecutiveFails += 1;
      AppDebugLog.homeWidget(
        'range v2 page=$page fail consecutive=$consecutiveFails',
      );
      if (consecutiveFails >= 3) break;
      continue;
    }
    consecutiveFails = 0;
    for (final r in chunk.listDesc) {
      byId[r.id] = r;
    }
    AppDebugLog.homeWidget(
      'range v2 page=$page got=${chunk.listDesc.length} total=${chunk.total}',
    );
    if (!chunk.hasMore || chunk.listDesc.isEmpty) break;
    page += 1;
  }

  final merged = byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  AppDebugLog.homeWidget('range ready merged=${merged.length}');
  return merged;
}
