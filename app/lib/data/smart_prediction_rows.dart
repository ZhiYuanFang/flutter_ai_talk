import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
import 'models.dart';

/// 智能预测页一行：事件 + 可选预测 + 每日代表点（解释 nextAt 时刻）。
class SmartPredictionRow {
  const SmartPredictionRow({
    required this.eventId,
    required this.eventName,
    required this.colorHex,
    required this.forecastEnabled,
    required this.prediction,
    required this.chartPoints,
    this.lastAt,
  });

  final String eventId;
  final String eventName;
  final String colorHex;
  final bool forecastEnabled;
  final EventNextPrediction? prediction;

  /// 每日至多一点，按日升序；用于解释推算 TOD。
  final List<DateTime> chartPoints;

  /// 该 root 最近一次发生时刻（与 [occurrenceInstant] 一致，含进行中）。
  final DateTime? lastAt;
}

/// root 下历史记录的最近发生时刻。
DateTime? latestOccurrenceAtForRecords(List<HistoryRecord> records) {
  DateTime? latest;
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: true);
    if (t == null) continue;
    if (latest == null || t.isAfter(latest)) latest = t;
  }
  return latest;
}

/// 是否为回忆种子伪记录（不得进喂养编辑 Sheet）。
bool isPredictionRecallSeedRecord(HistoryRecord record) {
  if (record.id.startsWith('recall_seed_')) return true;
  return record.rawPayload['_predictionRecallSeed'] == true;
}

/// 真历史中某 root 最近一条记录（按 [occurrenceInstant]，含进行中）。
HistoryRecord? latestRealHistoryRecordForRoot({
  required String rootEventId,
  required List<HistoryRecord> realHistory,
  required List<EventDefinition> catalog,
}) {
  final root = rootEventId.trim();
  if (root.isEmpty) return null;
  final byKey = groupHistoryByRootEvent(history: realHistory, catalog: catalog);
  List<HistoryRecord> bucket = const [];
  final direct = byKey[root];
  if (direct != null) {
    bucket = direct;
  } else {
    for (final e in byKey.entries) {
      if (catalogIdsEqual(e.key, root)) {
        bucket = e.value;
        break;
      }
    }
  }
  HistoryRecord? best;
  DateTime? bestAt;
  for (final r in bucket) {
    if (isPredictionRecallSeedRecord(r)) continue;
    final t = occurrenceInstant(r, includeActive: true);
    if (t == null) continue;
    if (bestAt == null || t.isAfter(bestAt)) {
      bestAt = t;
      best = r;
    }
  }
  return best;
}

/// 合并多源真历史后取 root 最新记录（后写覆盖同 id）。
HistoryRecord? latestRealHistoryRecordForRootFromSources({
  required String rootEventId,
  required List<EventDefinition> catalog,
  required List<HistoryRecord> homeItems,
  required List<HistoryRecord> rangeItems,
}) {
  final byId = <String, HistoryRecord>{};
  final noId = <HistoryRecord>[];
  for (final r in [...rangeItems, ...homeItems]) {
    if (isPredictionRecallSeedRecord(r)) continue;
    final id = r.id.trim();
    if (id.isEmpty) {
      noId.add(r);
    } else {
      byId[id] = r;
    }
  }
  return latestRealHistoryRecordForRoot(
    rootEventId: rootEventId,
    realHistory: [...byId.values, ...noId],
    catalog: catalog,
  );
}

/// 按根 eventId 聚合历史（与 [predictAllUpcoming] 分组一致）。
Map<String, List<HistoryRecord>> groupHistoryByRootEvent({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
}) {
  final idToDef = <String, EventDefinition>{};
  for (final d in catalog) {
    if (d.id.isNotEmpty) idToDef[d.id] = d;
  }

  String rootIdFor(String id) {
    var cur = id.trim();
    if (cur.isEmpty) return cur;
    final seen = <String>{};
    while (true) {
      if (seen.contains(cur)) return cur;
      seen.add(cur);
      final def = idToDef[cur];
      final p = def?.parentId?.trim();
      if (p == null || p.isEmpty) return cur;
      cur = p;
    }
  }

  final byKey = <String, List<HistoryRecord>>{};
  for (final r in history) {
    final id = historyRecordEventId(r);
    String key;
    if (id.isNotEmpty) {
      key = rootIdFor(id);
    } else {
      final def = lookupEventForRecord(catalog, r);
      if (def != null && def.id.isNotEmpty) {
        key = rootIdFor(def.id);
      } else {
        key = historyRecordEventKey(r);
      }
    }
    if (key.isEmpty) continue;
    byKey.putIfAbsent(key, () => []).add(r);
  }
  return byKey;
}

/// 当日时刻与锚点的环形分钟差（0–12h）。
int todCircularDiffMinutes(DateTime t, int anchorMinutes) {
  final m = t.hour * 60 + t.minute;
  var d = (m - anchorMinutes).abs();
  if (d > 12 * 60) d = 24 * 60 - d;
  return d;
}

/// 折线取点：过去日（today 前）每天至多一历史点（TOD 近 [anchorTod]）；
/// 今日仅当 [anchorTod]/nextAt 同自然日时画 [anchorTod]，不用今日已发生点。
/// [pastDaysBeforeToday]：今天之前纳入的自然日数（6→近7日；2→前天/昨天/今天）。
List<DateTime> dailyPointsNearAnchorTod({
  required List<HistoryRecord> records,
  required DateTime now,
  required DateTime anchorTod,
  int pastDaysBeforeToday = 6,
}) {
  final pastN = pastDaysBeforeToday < 0 ? 0 : pastDaysBeforeToday;
  final today = DateTime(now.year, now.month, now.day);
  final startDay = today.subtract(Duration(days: pastN));
  final lastPastIndex = pastN - 1;
  final anchorMinutes = anchorTod.hour * 60 + anchorTod.minute;
  final byDay = <int, List<DateTime>>{};
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: true);
    if (t == null) continue;
    if (t.isBefore(startDay) || t.isAfter(now)) continue;
    final day = DateTime(t.year, t.month, t.day);
    // 今日已发生不参与代表点
    if (!day.isBefore(today)) continue;
    final dayIndex = day.difference(startDay).inDays;
    if (dayIndex < 0 || dayIndex > lastPastIndex) continue;
    byDay.putIfAbsent(dayIndex, () => []).add(t);
  }

  final out = <DateTime>[];
  for (var i = 0; i < pastN; i++) {
    final list = byDay[i];
    if (list == null || list.isEmpty) continue;
    var best = list.first;
    var bestDiff = todCircularDiffMinutes(best, anchorMinutes);
    for (final t in list.skip(1)) {
      final d = todCircularDiffMinutes(t, anchorMinutes);
      if (d < bestDiff) {
        bestDiff = d;
        best = t;
      }
    }
    out.add(best);
  }
  // 仅当 nextAt 落在今天：今日点 = nextAt（可晚于 now / 同日逾期）
  final anchorDay =
      DateTime(anchorTod.year, anchorTod.month, anchorTod.day);
  if (anchorDay == today) {
    out.add(anchorTod.toLocal());
  }
  out.sort();
  return out;
}

/// 合并 home∪range 真历史（同 id 后写覆盖；排除回忆种子伪记录）。
List<HistoryRecord> mergeRealHistoryById({
  required List<HistoryRecord> rangeItems,
  required List<HistoryRecord> homeItems,
}) {
  final byId = <String, HistoryRecord>{};
  final noId = <HistoryRecord>[];
  for (final r in [...rangeItems, ...homeItems]) {
    if (isPredictionRecallSeedRecord(r)) continue;
    final id = r.id.trim();
    if (id.isEmpty) {
      noId.add(r);
    } else {
      byId[id] = r;
    }
  }
  return [...byId.values, ...noId];
}

/// 构建预测页行：目录非子根全集（含无历史 / 关推演）；排序优先可预测的 nextAt。
/// [history] 必须为真喂养（不得含回忆种子伪记录）；[recallIntervalsByRoot] 仅作间隔旁路。
List<SmartPredictionRow> buildSmartPredictionRows({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required DateTime now,
  required DateTime birthDate,
  required Set<String> disabledForecastIds,
  Set<String> activeEventKeys = const {},
  Map<String, Duration> recallIntervalsByRoot = const {},
}) {
  final byKey = groupHistoryByRootEvent(history: history, catalog: catalog);
  final roots = rootEvents(catalog);
  // 无根目录时无法出卡（加载中由 UI 处理）；不再因无历史直接空列表。
  if (roots.isEmpty) return const [];

  final enabledHistory = <HistoryRecord>[
    for (final e in byKey.entries)
      if (!disabledForecastIds.contains(e.key)) ...e.value,
  ];
  final predictions = predictAllUpcoming(
    history: enabledHistory,
    catalog: catalog,
    now: now,
    birthDate: birthDate,
    activeEventKeys: {
      for (final k in activeEventKeys)
        if (!disabledForecastIds.contains(k)) k,
    },
    recallIntervalsByRoot: {
      for (final e in recallIntervalsByRoot.entries)
        if (!disabledForecastIds.contains(e.key) &&
            e.value >= kMinIntervalForPrediction)
          e.key: e.value,
    },
  );
  final predById = {for (final p in predictions) p.eventId: p};

  List<HistoryRecord> recordsForRoot(String rootId) {
    final direct = byKey[rootId];
    if (direct != null) return direct;
    for (final e in byKey.entries) {
      if (catalogIdsEqual(e.key, rootId)) return e.value;
    }
    return const [];
  }

  final rows = <SmartPredictionRow>[];
  final coveredKeys = <String>{};
  for (final root in roots) {
    final key = root.id.trim();
    if (key.isEmpty) continue;
    final records = recordsForRoot(key);
    for (final e in byKey.entries) {
      if (catalogIdsEqual(e.key, key)) coveredKeys.add(e.key);
    }
    coveredKeys.add(key);
    final name = root.name.trim().isNotEmpty
        ? root.name.trim()
        : (records.isNotEmpty && records.last.eventName.trim().isNotEmpty
            ? records.last.eventName.trim()
            : '未命名事件');
    final enabled = !disabledForecastIds.contains(key);
    final lastAt = latestOccurrenceAtForRecords(records);
    final pred = enabled ? predById[key] : null;
    List<DateTime> points = const [];
    if (enabled && pred != null && records.isNotEmpty) {
      points = dailyPointsNearAnchorTod(
        records: records,
        now: now,
        anchorTod: pred.nextAt,
      );
    }
    rows.add(
      SmartPredictionRow(
        eventId: key,
        eventName: name,
        colorHex: colorHexFromEvent(root),
        forecastEnabled: enabled,
        prediction: pred,
        chartPoints: points,
        lastAt: lastAt,
      ),
    );
  }

  // 历史里出现、但无法映射到当前目录根的孤立键：仍保留一行以免丢数据。
  for (final entry in byKey.entries) {
    final key = entry.key;
    if (key.isEmpty || coveredKeys.contains(key)) continue;
    if (coveredKeys.any((c) => catalogIdsEqual(c, key))) continue;
    final def = lookupEventById(catalog, key);
    final name = def?.name.trim().isNotEmpty == true
        ? def!.name.trim()
        : (entry.value.last.eventName.trim().isEmpty
            ? '未知事件'
            : entry.value.last.eventName.trim());
    final enabled = !disabledForecastIds.contains(key);
    final pred = enabled ? predById[key] : null;
    List<DateTime> points = const [];
    if (enabled && pred != null) {
      points = dailyPointsNearAnchorTod(
        records: entry.value,
        now: now,
        anchorTod: pred.nextAt,
      );
    }
    rows.add(
      SmartPredictionRow(
        eventId: key,
        eventName: name,
        colorHex: colorHexFromEvent(def),
        forecastEnabled: enabled,
        prediction: pred,
        chartPoints: points,
        lastAt: latestOccurrenceAtForRecords(entry.value),
      ),
    );
  }

  int rank(SmartPredictionRow r) {
    if (r.forecastEnabled && r.prediction != null) return 0;
    if (r.forecastEnabled) return 1;
    return 2;
  }

  rows.sort((a, b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    if (ra == 0) {
      return a.prediction!.nextAt.compareTo(b.prediction!.nextAt);
    }
    return a.eventName.compareTo(b.eventName);
  });
  return rows;
}

/// 顶栏「最近下一步」：推演开、未 skip、有预测，取 nextAt 最早。
EventNextPrediction? pickNearestPrediction({
  required List<EventNextPrediction> predictions,
  required Set<String> disabledForecastIds,
  required Set<String> skippedIds,
}) {
  EventNextPrediction? best;
  for (final p in predictions) {
    if (disabledForecastIds.contains(p.eventId)) continue;
    if (skippedIds.contains(p.eventId)) continue;
    if (best == null || p.nextAt.isBefore(best.nextAt)) best = p;
  }
  return best;
}

/// 「接下来3小时」段落：推演开、有预测、`nextAt ≤ now+3h`（含超时），按 nextAt 升序。
List<String> buildNextThreeHoursSegments(
  List<SmartPredictionRow> rows,
  DateTime now,
) {
  final deadline = now.add(const Duration(hours: 3));
  final matched = <SmartPredictionRow>[];
  for (final r in rows) {
    if (!r.forecastEnabled) continue;
    final p = r.prediction;
    if (p == null) continue;
    // 晚于窗右沿则排除；超时（早于 now）仍纳入
    if (p.nextAt.isAfter(deadline)) continue;
    matched.add(r);
  }
  matched.sort((a, b) => a.prediction!.nextAt.compareTo(b.prediction!.nextAt));
  return [
    for (final r in matched)
      '${_twoDigits(r.prediction!.nextAt.hour)}:${_twoDigits(r.prediction!.nextAt.minute)} 左右${r.eventName}',
  ];
}

/// 用「 → 」连接段落；无段落时返回 null。
String? buildNextThreeHoursTimelineText(
  List<SmartPredictionRow> rows,
  DateTime now,
) {
  final segs = buildNextThreeHoursSegments(rows, now);
  if (segs.isEmpty) return null;
  return segs.join(' → ');
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
