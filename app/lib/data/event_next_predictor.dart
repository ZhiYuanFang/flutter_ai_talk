import 'dart:math' as math;

import 'appointment_event.dart';
import 'baby_age.dart';
import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'history_line_format.dart';
import 'models.dart';

const kMinIntervalForPrediction = Duration(minutes: 15);
const kMinSamplesForPrediction = 2;

/// 半衰期（天）按月龄分段。
int halfLifeDaysForBirthDate(DateTime birthDate, DateTime now) {
  if (!isUsableBabyBirthDate(birthDate, now)) return 14;
  final months = babyAgeInMonths(birthDate, now);
  if (months < 2) return 7;
  if (months < 4) return 10;
  if (months < 6) return 14;
  if (months < 12) return 21;
  return 30;
}

int timeOfDayBucket(DateTime t) {
  final h = t.hour;
  if (h < 6) return 0;
  if (h < 9) return 1;
  if (h < 12) return 2;
  if (h < 15) return 3;
  if (h < 18) return 4;
  return 5;
}

bool bucketsAdjacent(int a, int b) {
  if (a == b) return true;
  return (a - b).abs() == 1 || (a == 0 && b == 5) || (a == 5 && b == 0);
}

double bucketWeight(int sampleBucket, int anchorBucket) {
  if (sampleBucket == anchorBucket) return 1.0;
  if (bucketsAdjacent(sampleBucket, anchorBucket)) return 0.6;
  return 0.2;
}

double recencyWeight(double ageDays, int halfLifeDays) {
  if (halfLifeDays <= 0) return 1.0;
  return math.exp(-math.ln2 * ageDays / halfLifeDays);
}

DateTime? occurrenceInstant(HistoryRecord record, {bool includeActive = false}) {
  final p = record.rawPayload;
  if (isActiveTimingRecord(record)) {
    if (!includeActive) return null;
    // Treat an active timing record as an occurrence: prefer startTime, fall back to createdAt.
    final start = parseHistoryInstant(p['startTime']);
    return start ?? record.createdAt;
  }
  final n = historyPayloadInt(p, 'eventNumber');
  if (n == 0) {
    final end = parseHistoryInstant(p['endTime']);
    return end;
  }
  return parseHistoryInstant(p['startTime']) ?? record.createdAt;
}

Duration? weightedMedianInterval(
  List<({Duration interval, double weight})> samples,
) {
  if (samples.isEmpty) return null;
  final sorted = [...samples]..sort((a, b) => a.interval.compareTo(b.interval));
  final total = sorted.fold<double>(0, (s, e) => s + e.weight);
  if (total <= 0) return sorted[sorted.length ~/ 2].interval;
  var acc = 0.0;
  for (final s in sorted) {
    acc += s.weight;
    if (acc >= total / 2) return s.interval;
  }
  return sorted.last.interval;
}

class EventNextPrediction {
  const EventNextPrediction({
    required this.eventId,
    required this.eventName,
    required this.lastAt,
    required this.nextAt,
    required this.colorHex,
    required this.confidence,
  });

  final String eventId;
  final String eventName;
  final DateTime lastAt;
  final DateTime nextAt;
  final String colorHex;
  final double confidence;

  bool isOverdue(DateTime now) => nextAt.isBefore(now);
}

List<({Duration interval, double weight})> _collectWeightedIntervals({
  required List<DateTime> times,
  required int anchorBucket,
  required int halfLifeDays,
  required DateTime now,
  required bool strictBuckets,
}) {
  final out = <({Duration interval, double weight})>[];
  for (var i = 1; i < times.length; i++) {
    final delta = times[i].difference(times[i - 1]);
    if (delta < kMinIntervalForPrediction) continue;
    final b = timeOfDayBucket(times[i - 1]);
    final bw = strictBuckets ? bucketWeight(b, anchorBucket) : 1.0;
    final ageDays = now.difference(times[i]).inHours / 24.0;
    final w = bw * recencyWeight(ageDays, halfLifeDays);
    if (w > 0.001) out.add((interval: delta, weight: w));
  }
  return out;
}

// 预测核心算法逻辑
EventNextPrediction? predictNextForEventKey({
  required String eventKey,
  required String eventName,
  required List<HistoryRecord> records,
  required DateTime now,
  required int halfLifeDays,
  String colorHex = '#5BA3E8',
  bool includeActive = false,
  /// 真样本未达加权中位门槛时的间隔旁路（回忆种子）；不得单独提供 lastAt。
  Duration? recallIntervalFallback,
}) {
  final times = <DateTime>[];
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: includeActive);
    if (t != null) times.add(t);
  }
  // 无真发生时刻 → 不预测（不得用种子 lastAt 顶替）
  if (times.isEmpty) return null;
  times.sort();
  final lastAt = times.last;
  final anchorBucket = timeOfDayBucket(lastAt);

  Duration? median;
  var confidence = 0.3;
  if (times.length >= 2) {
    var samples = _collectWeightedIntervals(
      times: times,
      anchorBucket: anchorBucket,
      halfLifeDays: halfLifeDays,
      now: now,
      strictBuckets: true,
    );
    if (samples.length < kMinSamplesForPrediction) {
      samples = _collectWeightedIntervals(
        times: times,
        anchorBucket: anchorBucket,
        halfLifeDays: halfLifeDays,
        now: now,
        strictBuckets: false,
      );
    }
    if (samples.length >= kMinSamplesForPrediction) {
      median = weightedMedianInterval(samples);
      if (median != null) {
        confidence = math.min(1.0, samples.length / 7.0);
      }
    }
  }

  final fallback = recallIntervalFallback;
  final interval = median ??
      (fallback != null && fallback >= kMinIntervalForPrediction
          ? fallback
          : null);
  if (interval == null) return null;

  return EventNextPrediction(
    eventId: eventKey,
    eventName: eventName,
    lastAt: lastAt,
    nextAt: lastAt.add(interval),
    colorHex: colorHex,
    confidence: confidence,
  );
}

String colorHexFromEvent(EventDefinition? def) {
  final raw = def?.colorRaw;
  if (raw == null || raw.trim().isEmpty) return '#5BA3E8';
  var s = raw.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6 || s.length == 8) return '#${s.length == 8 ? s.substring(2) : s}';
  return '#5BA3E8';
}

List<EventNextPrediction> predictAllUpcoming({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required DateTime now,
  required DateTime birthDate,
  Set<String> activeEventKeys = const {},
  /// rootId → 回忆间隔旁路（仅真样本不足时使用）。
  Map<String, Duration> recallIntervalsByRoot = const {},
  /// 根 eventId → 已缓存的预约 nextAt 秒（含 0）；预约根忽略间隔与种子。
  Map<String, int> appointmentNextAtSecByRoot = const {},
}) {
  final halfLife = halfLifeDaysForBirthDate(birthDate, now);
  // Build a quick lookup for catalog by id
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

  Duration? recallForRoot(String rootKey) {
    final direct = recallIntervalsByRoot[rootKey];
    if (direct != null) return direct;
    for (final e in recallIntervalsByRoot.entries) {
      if (catalogIdsEqual(e.key, rootKey)) return e.value;
    }
    return null;
  }

  int? appointmentSecForRoot(String rootKey) {
    final direct = appointmentNextAtSecByRoot[rootKey];
    if (direct != null) return direct;
    for (final e in appointmentNextAtSecByRoot.entries) {
      if (catalogIdsEqual(e.key, rootKey)) return e.value;
    }
    return null;
  }

  final byKey = <String, List<HistoryRecord>>{};
  for (final r in history) {
    final id = historyRecordEventId(r);
    String key;
    if (id.isNotEmpty) {
      key = rootIdFor(id);
    } else {
      // no id on record: try to resolve by name to a catalog entry then to its root,
      // otherwise fall back to the record's eventName (name-based grouping).
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

  final out = <EventNextPrediction>[];
  final coveredAppointment = <String>{};

  for (final entry in byKey.entries) {
    final def = lookupEventById(catalog, entry.key);
    final name = def?.name.trim().isNotEmpty == true
        ? def!.name.trim()
        : (entry.value.last.eventName.trim().isEmpty
            ? '未知事件'
            : entry.value.last.eventName.trim());
    // 预约根：不走间隔/种子；有正 nextAt 则用约定时间
    if (catalogRootIsAppointment(entry.key, catalog)) {
      coveredAppointment.add(entry.key);
      final sec = appointmentSecForRoot(entry.key);
      if (sec == null || sec < 1) continue;
      final nextAt = appointmentNextAtFromSec(sec)!;
      final lastAt =
          latestOccurrenceFromRecords(entry.value) ?? nextAt;
      out.add(
        EventNextPrediction(
          eventId: entry.key,
          eventName: name,
          lastAt: lastAt,
          nextAt: nextAt,
          colorHex: colorHexFromEvent(def),
          confidence: 1.0,
        ),
      );
      continue;
    }
    final p = predictNextForEventKey(
      eventKey: entry.key,
      eventName: name,
      records: entry.value,
      now: now,
      halfLifeDays: halfLife,
      colorHex: colorHexFromEvent(def),
      includeActive: true,
      recallIntervalFallback: recallForRoot(entry.key),
    );
    if (p != null) out.add(p);
  }

  // 无历史但已有约定的预约根：仍产出预测节点
  for (final root in rootEvents(catalog)) {
    final key = root.id.trim();
    if (key.isEmpty) continue;
    if (!catalogRootIsAppointment(key, catalog)) continue;
    if (coveredAppointment.any((c) => catalogIdsEqual(c, key))) continue;
    final sec = appointmentSecForRoot(key);
    if (sec == null || sec < 1) continue;
    final nextAt = appointmentNextAtFromSec(sec)!;
    out.add(
      EventNextPrediction(
        eventId: key,
        eventName: root.name.trim().isNotEmpty ? root.name.trim() : '未命名事件',
        lastAt: nextAt,
        nextAt: nextAt,
        colorHex: colorHexFromEvent(root),
        confidence: 1.0,
      ),
    );
  }

  out.sort((a, b) => a.nextAt.compareTo(b.nextAt));
  return out;
}

/// 记录列表最近发生时刻（含进行中）。
DateTime? latestOccurrenceFromRecords(List<HistoryRecord> records) {
  DateTime? latest;
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: true);
    if (t == null) continue;
    if (latest == null || t.isAfter(latest)) latest = t;
  }
  return latest;
}
