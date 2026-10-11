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

/// 胜出量线种类（与 pending / Go 契约 `expectKind` 对齐）。
const kExpectKindDuration = 'duration';
const kExpectKindAmount = 'amount';

class EventNextPrediction {
  const EventNextPrediction({
    required this.eventId,
    required this.eventName,
    required this.lastAt,
    required this.nextAt,
    required this.colorHex,
    required this.confidence,
    this.expectKind,
    this.expectDurationSec,
    this.expectAmount,
    this.expectUnit,
    this.expectLeafTitle,
  });

  final String eventId;
  final String eventName;
  final DateTime lastAt;
  final DateTime nextAt;
  final String colorHex;
  final double confidence;

  /// `duration` / `amount`；无胜出为 null。
  final String? expectKind;
  final int? expectDurationSec;
  final double? expectAmount;
  final String? expectUnit;
  final String? expectLeafTitle;

  bool isOverdue(DateTime now) => nextAt.isBefore(now);

  bool get hasExpect {
    final kind = expectKind?.trim();
    if (kind == kExpectKindDuration) {
      return (expectDurationSec ?? 0) > 0;
    }
    if (kind == kExpectKindAmount) {
      return (expectAmount ?? 0) > 0;
    }
    return false;
  }

  EventNextPrediction copyWith({
    String? eventId,
    String? eventName,
    DateTime? lastAt,
    DateTime? nextAt,
    String? colorHex,
    double? confidence,
    Object? expectKind = _expectUnset,
    Object? expectDurationSec = _expectUnset,
    Object? expectAmount = _expectUnset,
    Object? expectUnit = _expectUnset,
    Object? expectLeafTitle = _expectUnset,
  }) {
    return EventNextPrediction(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      lastAt: lastAt ?? this.lastAt,
      nextAt: nextAt ?? this.nextAt,
      colorHex: colorHex ?? this.colorHex,
      confidence: confidence ?? this.confidence,
      expectKind: identical(expectKind, _expectUnset)
          ? this.expectKind
          : expectKind as String?,
      expectDurationSec: identical(expectDurationSec, _expectUnset)
          ? this.expectDurationSec
          : expectDurationSec as int?,
      expectAmount: identical(expectAmount, _expectUnset)
          ? this.expectAmount
          : expectAmount as double?,
      expectUnit: identical(expectUnit, _expectUnset)
          ? this.expectUnit
          : expectUnit as String?,
      expectLeafTitle: identical(expectLeafTitle, _expectUnset)
          ? this.expectLeafTitle
          : expectLeafTitle as String?,
    );
  }
}

const Object _expectUnset = Object();

/// 是否为回忆种子伪记录（不得进量样本）。
bool _isRecallSeedRecord(HistoryRecord record) {
  if (record.id.startsWith('recall_seed_')) return true;
  return record.rawPayload['_predictionRecallSeed'] == true;
}

/// 记录上的用量单位（payload）。
String _recordEventUnit(HistoryRecord record) {
  final p = record.rawPayload;
  final fromRow = (p['eventUnit'] as String?)?.trim() ?? '';
  if (fromRow.isNotEmpty) return fromRow;
  return (p['event_unit'] as String?)?.trim() ?? '';
}

/// 可计量模态：已结束计时 → duration；正数量 → amount。
String? countableExpectKind(HistoryRecord record) {
  if (_isRecallSeedRecord(record)) return null;
  if (isActiveTimingRecord(record)) return null;
  final p = record.rawPayload;
  final n = historyPayloadInt(p, 'eventNumber');
  if (n == 0) {
    final start = parseHistoryInstant(p['startTime']);
    final end = parseHistoryInstant(p['endTime']);
    if (start == null || end == null || !end.isAfter(start)) return null;
    if (end.difference(start).inSeconds <= 0) return null;
    return kExpectKindDuration;
  }
  if (n > 0) return kExpectKindAmount;
  return null;
}

double? weightedMedianValue(List<({double value, double weight})> samples) {
  if (samples.isEmpty) return null;
  final sorted = [...samples]..sort((a, b) => a.value.compareTo(b.value));
  final total = sorted.fold<double>(0, (s, e) => s + e.weight);
  if (total <= 0) return sorted[sorted.length ~/ 2].value;
  var acc = 0.0;
  for (final s in sorted) {
    acc += s.weight;
    if (acc >= total / 2) return s.value;
  }
  return sorted.last.value;
}

List<({double value, double weight})> _collectWeightedMetricSamples({
  required List<({DateTime at, double value})> points,
  required int anchorBucket,
  required int halfLifeDays,
  required DateTime now,
  required bool strictBuckets,
}) {
  final out = <({double value, double weight})>[];
  for (final p in points) {
    final b = timeOfDayBucket(p.at);
    final bw = strictBuckets ? bucketWeight(b, anchorBucket) : 1.0;
    final ageDays = now.difference(p.at).inHours / 24.0;
    final w = bw * recencyWeight(ageDays, halfLifeDays);
    if (w > 0.001) out.add((value: p.value, weight: w));
  }
  return out;
}

/// 从点列算有把握的加权中位；不足 [kMinSamplesForPrediction] 返回 null。
double? _confidentWeightedMedian({
  required List<({DateTime at, double value})> points,
  required DateTime anchorAt,
  required int halfLifeDays,
  required DateTime now,
}) {
  if (points.length < kMinSamplesForPrediction) return null;
  final anchorBucket = timeOfDayBucket(anchorAt);
  var samples = _collectWeightedMetricSamples(
    points: points,
    anchorBucket: anchorBucket,
    halfLifeDays: halfLifeDays,
    now: now,
    strictBuckets: true,
  );
  if (samples.length < kMinSamplesForPrediction) {
    samples = _collectWeightedMetricSamples(
      points: points,
      anchorBucket: anchorBucket,
      halfLifeDays: halfLifeDays,
      now: now,
      strictBuckets: false,
    );
  }
  if (samples.length < kMinSamplesForPrediction) return null;
  return weightedMedianValue(samples);
}

/// 收集已结束计时样本点（不含进行中、不含种子）。
List<({DateTime at, double value})> _durationSamplePoints(
  List<HistoryRecord> records,
) {
  final durationPoints = <({DateTime at, double value})>[];
  for (final r in records) {
    if (_isRecallSeedRecord(r)) continue;
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    if (n != 0) continue;
    if (isActiveTimingRecord(r)) continue;
    final start = parseHistoryInstant(p['startTime']);
    final end = parseHistoryInstant(p['endTime']);
    if (start == null || end == null || !end.isAfter(start)) continue;
    final sec = end.difference(start).inSeconds;
    if (sec <= 0) continue;
    durationPoints.add((at: end, value: sec.toDouble()));
  }
  return durationPoints;
}

/// 仅 duration 线有把握时的秒数（进行中 ETA 用；与胜出 kind 无关）。
int? confidentDurationExpectSec({
  required List<HistoryRecord> records,
  required DateTime now,
  required int halfLifeDays,
  required DateTime anchorAt,
}) {
  final median = _confidentWeightedMedian(
    points: _durationSamplePoints(records),
    anchorAt: anchorAt,
    halfLifeDays: halfLifeDays,
    now: now,
  );
  if (median == null || median <= 0) return null;
  return median.round().clamp(1, 1 << 31);
}

/// 根下 duration / amount 双线推演并择一胜出。
({
  String kind,
  int? durationSec,
  double? amount,
  String? unit,
  String? leafTitle,
})? resolveWinningExpect({
  required List<HistoryRecord> records,
  required String rootEventName,
  required DateTime now,
  required int halfLifeDays,
  required DateTime anchorAt,
}) {
  final durationPoints = _durationSamplePoints(records);
  final amountPoints = <({DateTime at, double value, String unit, String leaf})>[];

  for (final r in records) {
    if (_isRecallSeedRecord(r)) continue;
    final p = r.rawPayload;
    final n = historyPayloadInt(p, 'eventNumber');
    if (n > 0) {
      final at = occurrenceInstant(r, includeActive: false) ?? r.createdAt;
      final leaf = r.eventName.trim();
      amountPoints.add((
        at: at,
        value: n.toDouble(),
        unit: _recordEventUnit(r),
        leaf: leaf,
      ));
    }
  }

  final durationMedian = _confidentWeightedMedian(
    points: durationPoints,
    anchorAt: anchorAt,
    halfLifeDays: halfLifeDays,
    now: now,
  );
  final amountMedian = _confidentWeightedMedian(
    points: [
      for (final a in amountPoints) (at: a.at, value: a.value),
    ],
    anchorAt: anchorAt,
    halfLifeDays: halfLifeDays,
    now: now,
  );

  final durationOk = durationMedian != null && durationMedian > 0;
  final amountOk = amountMedian != null && amountMedian > 0;
  if (!durationOk && !amountOk) return null;

  // 最近可计量模态决胜；该线无把握则回退另一条
  HistoryRecord? latestCountable;
  DateTime? latestAt;
  for (final r in records) {
    final kind = countableExpectKind(r);
    if (kind == null) continue;
    final t = occurrenceInstant(r, includeActive: false);
    if (t == null) continue;
    if (latestAt == null || t.isAfter(latestAt)) {
      latestAt = t;
      latestCountable = r;
    }
  }
  final latestRec = latestCountable;
  final latestKind =
      latestRec != null ? countableExpectKind(latestRec) : null;

  final String pickKind;
  if (latestKind == kExpectKindDuration && durationOk) {
    pickKind = kExpectKindDuration;
  } else if (latestKind == kExpectKindAmount && amountOk) {
    pickKind = kExpectKindAmount;
  } else if (durationOk) {
    pickKind = kExpectKindDuration;
  } else {
    pickKind = kExpectKindAmount;
  }

  if (pickKind == kExpectKindDuration) {
    final sec = durationMedian!.round().clamp(1, 1 << 31);
    return (
      kind: kExpectKindDuration,
      durationSec: sec,
      amount: null,
      unit: null,
      leafTitle: null,
    );
  }

  // amount：单位取最近非空；叶子名取最近 amount 样本且异于根名
  amountPoints.sort((a, b) => a.at.compareTo(b.at));
  var unit = '';
  var leaf = '';
  for (var i = amountPoints.length - 1; i >= 0; i--) {
    final u = amountPoints[i].unit.trim();
    if (unit.isEmpty && u.isNotEmpty) unit = u;
    final lf = amountPoints[i].leaf.trim();
    if (leaf.isEmpty && lf.isNotEmpty) leaf = lf;
    if (unit.isNotEmpty && leaf.isNotEmpty) break;
  }
  final root = rootEventName.trim();
  final leafTitle =
      leaf.isNotEmpty && leaf != root ? leaf : null;

  return (
    kind: kExpectKindAmount,
    durationSec: null,
    amount: amountMedian!,
    unit: unit.isEmpty ? null : unit,
    leafTitle: leafTitle,
  );
}

/// 将胜出 expect 挂到已有 nextAt 预测上。
EventNextPrediction attachWinningExpect({
  required EventNextPrediction prediction,
  required List<HistoryRecord> records,
  required DateTime now,
  required int halfLifeDays,
}) {
  final win = resolveWinningExpect(
    records: records,
    rootEventName: prediction.eventName,
    now: now,
    halfLifeDays: halfLifeDays,
    anchorAt: prediction.lastAt,
  );
  if (win == null) {
    return prediction.copyWith(
      expectKind: null,
      expectDurationSec: null,
      expectAmount: null,
      expectUnit: null,
      expectLeafTitle: null,
    );
  }
  if (win.kind == kExpectKindDuration) {
    return prediction.copyWith(
      expectKind: kExpectKindDuration,
      expectDurationSec: win.durationSec,
      expectAmount: null,
      expectUnit: null,
      expectLeafTitle: null,
    );
  }
  return prediction.copyWith(
    expectKind: kExpectKindAmount,
    expectDurationSec: null,
    expectAmount: win.amount,
    expectUnit: win.unit,
    expectLeafTitle: win.leafTitle,
  );
}

/// 时长秒 →「1小时5分钟」/「不足1分钟」（对齐今日汇总风格）。
String formatExpectDurationFromSec(int sec) {
  if (sec < 60) return '不足1分钟';
  if (sec < 3600) return '${sec ~/ 60}分钟';
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  if (m == 0) return '$h小时';
  return '$h小时$m分钟';
}

String _formatExpectAmountNumber(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  final s = value.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// 预测卡次级文案；无 expect 返回 null。横屏可 [includeLeaf]=false。
String? formatPredictionExpectCardLabel(
  EventNextPrediction prediction, {
  bool includeLeaf = true,
}) {
  final kind = prediction.expectKind?.trim();
  if (kind == kExpectKindDuration) {
    final sec = prediction.expectDurationSec;
    if (sec == null || sec < 1) return null;
    return '预计约${formatExpectDurationFromSec(sec)}';
  }
  if (kind == kExpectKindAmount) {
    final a = prediction.expectAmount;
    if (a == null || a <= 0) return null;
    final qty = _formatExpectAmountNumber(a);
    final unit = prediction.expectUnit?.trim() ?? '';
    final leaf = includeLeaf ? (prediction.expectLeafTitle?.trim() ?? '') : '';
    return '预计约$qty$unit$leaf';
  }
  return null;
}

/// pending / 指纹用的 expect 身份串。
String expectFingerprintToken(EventNextPrediction p) {
  if (!p.hasExpect) return 'none';
  final kind = p.expectKind!.trim();
  if (kind == kExpectKindDuration) {
    return 'duration:${p.expectDurationSec}';
  }
  final amt = p.expectAmount;
  final amtStr = amt == null
      ? '0'
      : (amt == amt.roundToDouble() ? '${amt.toInt()}' : amt.toString());
  return 'amount:$amtStr:${p.expectUnit ?? ''}:${p.expectLeafTitle ?? ''}';
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
  /// 窗口无发生时的真 lastAt 回退（事件最近发生缓存）；不得用种子 lastAt。
  DateTime? cachedLastAt,
}) {
  final times = <DateTime>[];
  for (final r in records) {
    final t = occurrenceInstant(r, includeActive: includeActive);
    if (t != null) times.add(t);
  }
  final fallback = recallIntervalFallback;
  // 窗口无真发生：仅缓存 tip + 有效种子间隔可旁路（不得用种子 lastAt）
  if (times.isEmpty) {
    if (cachedLastAt == null) return null;
    if (fallback == null || fallback < kMinIntervalForPrediction) return null;
    return EventNextPrediction(
      eventId: eventKey,
      eventName: eventName,
      lastAt: cachedLastAt,
      nextAt: cachedLastAt.add(fallback),
      colorHex: colorHex,
      confidence: 0.3,
    );
  }
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
  /// 根 eventId → 本机曾见真发生 tip（窗口未命中时作 lastAt 回退）。
  Map<String, DateTime> lastAtCacheByRoot = const {},
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

  DateTime? cachedLastAtForRoot(String rootKey) {
    final direct = lastAtCacheByRoot[rootKey];
    if (direct != null) return direct;
    for (final e in lastAtCacheByRoot.entries) {
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
      cachedLastAt: cachedLastAtForRoot(entry.key),
    );
    if (p != null) {
      // 非预约根：挂上胜出用量/用时 expect
      out.add(
        attachWinningExpect(
          prediction: p,
          records: entry.value,
          now: now,
          halfLifeDays: halfLife,
        ),
      );
    }
  }

  final coveredPredict = <String>{
    for (final p in out) p.eventId,
  };

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
    coveredPredict.add(key);
  }

  // 窗口无该根记录，但缓存 tip + 种子间隔可旁路
  for (final root in rootEvents(catalog)) {
    final key = root.id.trim();
    if (key.isEmpty) continue;
    if (catalogRootIsAppointment(key, catalog)) continue;
    if (coveredPredict.any((c) => catalogIdsEqual(c, key))) continue;
    if (byKey.keys.any((k) => catalogIdsEqual(k, key))) continue;
    final cached = cachedLastAtForRoot(key);
    if (cached == null) continue;
    final p = predictNextForEventKey(
      eventKey: key,
      eventName: root.name.trim().isNotEmpty ? root.name.trim() : '未命名事件',
      records: const [],
      now: now,
      halfLifeDays: halfLife,
      colorHex: colorHexFromEvent(root),
      includeActive: true,
      recallIntervalFallback: recallForRoot(key),
      cachedLastAt: cached,
    );
    // 窗口无记录时无量样本，expect 自然为空
    if (p != null) out.add(p);
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
