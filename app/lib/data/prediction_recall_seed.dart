import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
import 'models.dart';
import 'smart_prediction_rows.dart';

/// 单根事件的预测回忆种子（不进喂养历史）。
class PredictionRecallSeed {
  const PredictionRecallSeed({
    required this.rootEventId,
    required this.leafEventId,
    required this.lastAt,
    required this.interval,
    required this.occurrenceAts,
  });

  final String rootEventId;
  final String leafEventId;
  final DateTime lastAt;
  final Duration interval;
  final List<DateTime> occurrenceAts;

  Map<String, dynamic> toJson() => {
        'rootEventId': rootEventId,
        'leafEventId': leafEventId,
        'lastAt': lastAt.toUtc().toIso8601String(),
        'intervalMinutes': interval.inMinutes,
        'occurrenceAts': [
          for (final t in occurrenceAts) t.toUtc().toIso8601String(),
        ],
      };

  static PredictionRecallSeed? fromJson(Map<String, dynamic> j) {
    final root = (j['rootEventId'] as String?)?.trim() ?? '';
    if (root.isEmpty) return null;
    final leaf = (j['leafEventId'] as String?)?.trim() ?? root;
    final lastRaw = j['lastAt'] as String?;
    if (lastRaw == null || lastRaw.isEmpty) return null;
    final lastAt = DateTime.tryParse(lastRaw)?.toLocal();
    if (lastAt == null) return null;
    final mins = (j['intervalMinutes'] as num?)?.toInt() ?? 0;
    if (mins < kMinIntervalForPrediction.inMinutes) return null;
    final interval = Duration(minutes: mins);
    final atsRaw = j['occurrenceAts'];
    final ats = <DateTime>[];
    if (atsRaw is List) {
      for (final e in atsRaw) {
        if (e is! String) continue;
        final t = DateTime.tryParse(e)?.toLocal();
        if (t != null) ats.add(t);
      }
    }
    if (ats.length < 3) {
      return PredictionRecallSeed(
        rootEventId: root,
        leafEventId: leaf,
        lastAt: lastAt,
        interval: interval,
        occurrenceAts: synthesizeOccurrenceAts(lastAt: lastAt, interval: interval),
      );
    }
    ats.sort();
    return PredictionRecallSeed(
      rootEventId: root,
      leafEventId: leaf,
      lastAt: lastAt,
      interval: interval,
      occurrenceAts: ats,
    );
  }
}

/// 自上次时刻按间隔回推至少 3 个发生点。
List<DateTime> synthesizeOccurrenceAts({
  required DateTime lastAt,
  required Duration interval,
}) {
  final d = interval < kMinIntervalForPrediction
      ? kMinIntervalForPrediction
      : interval;
  return [
    lastAt.subtract(d * 2),
    lastAt.subtract(d),
    lastAt,
  ];
}

/// 真历史（或任意记录集）是否已达推演样本门槛。
bool historyMeetsPredictorSampleGate(List<HistoryRecord> records) {
  final times = <DateTime>[];
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: true);
    if (t != null) times.add(t);
  }
  if (times.length < 2) return false;
  times.sort();
  var samples = 0;
  for (var i = 1; i < times.length; i++) {
    if (times[i].difference(times[i - 1]) >= kMinIntervalForPrediction) {
      samples++;
    }
  }
  return samples >= kMinSamplesForPrediction;
}

/// 种子合成点 → 仅内存伪 HistoryRecord（不上报、不写仓储）。
List<HistoryRecord> syntheticHistoryRecordsFromSeed(
  PredictionRecallSeed seed, {
  required String eventName,
}) {
  final leafId = seed.leafEventId.isEmpty ? seed.rootEventId : seed.leafEventId;
  final out = <HistoryRecord>[];
  for (var i = 0; i < seed.occurrenceAts.length; i++) {
    final t = seed.occurrenceAts[i];
    final unix = t.toUtc().millisecondsSinceEpoch ~/ 1000;
    out.add(
      HistoryRecord(
        id: 'recall_seed_${seed.rootEventId}_$i',
        createdAt: t,
        eventName: eventName,
        action: '回忆种子',
        rawPayload: {
          'eventId': int.tryParse(leafId) ?? leafId,
          'eventName': eventName,
          'eventNumber': 1,
          'startTime': unix,
          'endTime': unix,
          'remark': 'prediction_recall_seed',
          '_predictionRecallSeed': true,
        },
      ),
    );
  }
  return out;
}

/// 缺口根：真历史未达门槛、无有效种子、且未关推演。
List<EventDefinition> predictionRecallGapRoots({
  required List<EventDefinition> catalog,
  required List<HistoryRecord> realHistory,
  required Map<String, PredictionRecallSeed> seeds,
  required Set<String> disabledForecastIds,
}) {
  final byRoot = groupHistoryByRootEvent(history: realHistory, catalog: catalog);
  final roots = rootEvents(catalog);
  final out = <EventDefinition>[];
  for (final root in roots) {
    if (root.id.isEmpty) continue;
    if (disabledForecastIds.contains(root.id)) continue;
    final real = byRoot[root.id] ?? const <HistoryRecord>[];
    if (historyMeetsPredictorSampleGate(real)) continue;
    final seed = seeds[root.id];
    if (seed != null && seed.occurrenceAts.length >= 3) continue;
    out.add(root);
  }
  return out;
}

/// 丢弃真历史已达标的种子。
Set<String> rootIdsWhoseRealHistoryCaughtUp({
  required List<EventDefinition> catalog,
  required List<HistoryRecord> realHistory,
  required Iterable<String> seedRootIds,
}) {
  final byRoot = groupHistoryByRootEvent(history: realHistory, catalog: catalog);
  final drop = <String>{};
  for (final id in seedRootIds) {
    final real = byRoot[id] ?? const <HistoryRecord>[];
    if (historyMeetsPredictorSampleGate(real)) drop.add(id);
  }
  return drop;
}

/// 合并真历史 + 仍缺口根的种子伪记录。
List<HistoryRecord> mergeHistoryWithRecallSeeds({
  required List<HistoryRecord> realHistory,
  required List<EventDefinition> catalog,
  required Map<String, PredictionRecallSeed> seeds,
}) {
  final byRoot = groupHistoryByRootEvent(history: realHistory, catalog: catalog);
  final merged = List<HistoryRecord>.from(realHistory);
  for (final entry in seeds.entries) {
    final rootId = entry.key;
    final real = byRoot[rootId] ?? const <HistoryRecord>[];
    if (historyMeetsPredictorSampleGate(real)) continue;
    final def = lookupEventById(catalog, rootId);
    final name = def?.name.trim().isNotEmpty == true
        ? def!.name.trim()
        : '事件';
    merged.addAll(
      syntheticHistoryRecordsFromSeed(entry.value, eventName: name),
    );
  }
  return merged;
}
