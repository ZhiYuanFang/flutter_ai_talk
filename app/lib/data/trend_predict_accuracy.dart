import 'history_line_format.dart';
import 'history_mapper.dart';
import 'models.dart';

/// 开始时刻命中窗：|实际 − 预计| ≤ 30 分钟。
const kPredictAccuracyHitWindowSec = 1800;

/// 自然日键（本地年月日 0 点）。
DateTime predictAccuracyDayKey(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// 从 payload 读正 expectStartTime（unix 秒）；不可用 → null（不计样本、禁止重放）。
int? expectStartTimeSecFromPayload(Map<String, Object?> p) {
  final v = p['expectStartTime'];
  if (v is int) return v > 0 ? v : null;
  if (v is num) {
    final i = v.toInt();
    return i > 0 ? i : null;
  }
  final parsed = int.tryParse(v?.toString() ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

/// 单条合格准确率样本（预计 vs 实际）。
class PredictAccuracySample {
  const PredictAccuracySample({
    required this.day,
    required this.actualAt,
    required this.expectAt,
    required this.hit,
  });

  /// 实际发生所在自然日
  final DateTime day;

  /// 实际开始
  final DateTime actualAt;

  /// 预计开始（来自已存 expectStartTime）
  final DateTime expectAt;

  /// 是否落在命中窗内
  final bool hit;
}

/// 历史行 → 合格样本；无 expect* / 回忆种子 → 跳过（禁止重放）。
PredictAccuracySample? predictAccuracySampleFromRecord(HistoryRecord r) {
  // 回忆种子伪记录不计准确率（与 isPredictionRecallSeedRecord 同键）
  if (r.rawPayload['_predictionRecallSeed'] == true) return null;
  final expectSec = expectStartTimeSecFromPayload(r.rawPayload);
  if (expectSec == null) return null;
  // 实际开始：payload startTime，否则 createdAt
  final actualAt =
      parseHistoryInstant(r.rawPayload['startTime']) ?? r.createdAt;
  final actualSec = historyDateTimeToUnixSeconds(actualAt);
  if (actualSec <= 0) return null;
  final diff = (actualSec - expectSec).abs();
  final hit = diff <= kPredictAccuracyHitWindowSec;
  return PredictAccuracySample(
    day: predictAccuracyDayKey(actualAt),
    actualAt: actualAt.toLocal(),
    expectAt: DateTime.fromMillisecondsSinceEpoch(expectSec * 1000, isUtc: true)
        .toLocal(),
    hit: hit,
  );
}

/// 从历史列表收集合格样本（不重放）。
List<PredictAccuracySample> predictAccuracySamplesFromHistory(
  Iterable<HistoryRecord> records,
) {
  final out = <PredictAccuracySample>[];
  for (final r in records) {
    final s = predictAccuracySampleFromRecord(r);
    if (s != null) out.add(s);
  }
  // 按实际时刻升序，小结列表稳定
  out.sort((a, b) => a.actualAt.compareTo(b.actualAt));
  return out;
}

/// 近 N 日窗口日键：含今天，共 [pastDaysBeforeToday]+1 天（6→近7日）。
List<DateTime> predictAccuracyWindowDays({
  required DateTime now,
  int pastDaysBeforeToday = 6,
}) {
  final pastN = pastDaysBeforeToday < 0 ? 0 : pastDaysBeforeToday;
  final today = predictAccuracyDayKey(now);
  return [
    for (var i = pastN; i >= 0; i--) today.subtract(Duration(days: i)),
  ];
}

/// 与 [days] 等长；该日无合格样本时为 null（不画柱、不标 0%）。
List<int?> predictDailyAccuracyPercents({
  required List<DateTime> days,
  required List<PredictAccuracySample> samples,
}) {
  if (days.isEmpty) return const [];
  final hits = <DateTime, int>{};
  final counts = <DateTime, int>{};
  for (final s in samples) {
    final key = predictAccuracyDayKey(s.day);
    counts[key] = (counts[key] ?? 0) + 1;
    if (s.hit) hits[key] = (hits[key] ?? 0) + 1;
  }
  return [
    for (final d in days)
      () {
        final key = predictAccuracyDayKey(d);
        final n = counts[key] ?? 0;
        if (n < 1) return null;
        final h = hits[key] ?? 0;
        return (100.0 * h / n).round();
      }(),
  ];
}

/// 某自然日的合格样本明细（预测小结）。
List<PredictAccuracySample> predictAccuracySamplesForDay({
  required List<PredictAccuracySample> samples,
  required DateTime day,
}) {
  final key = predictAccuracyDayKey(day);
  return [
    for (final s in samples)
      if (predictAccuracyDayKey(s.day) == key) s,
  ];
}

// --- TrendPoint 适配（piece raw；趋势 UI 已回滚，保留供复用） ---

/// @nodoc 兼容旧名
DateTime trendAccuracyDayKey(DateTime t) => predictAccuracyDayKey(t);

bool trendPointIsAccuracySample(TrendPoint p) {
  final e = p.expectStartTimeSec;
  final a = p.actualStartSec;
  return e != null && e > 0 && a != null && a > 0;
}

bool trendAccuracySampleIsHit(TrendPoint p) {
  if (!trendPointIsAccuracySample(p)) return false;
  final diff = (p.actualStartSec! - p.expectStartTimeSec!).abs();
  return diff <= kPredictAccuracyHitWindowSec;
}

List<int?> trendDailyAccuracyPercents({
  required List<TrendPoint> daily,
  required List<TrendPoint> raw,
}) {
  final samples = <PredictAccuracySample>[];
  for (final p in raw) {
    if (!trendPointIsAccuracySample(p)) continue;
    final actualSec = p.actualStartSec!;
    final expectSec = p.expectStartTimeSec!;
    final actualAt =
        DateTime.fromMillisecondsSinceEpoch(actualSec * 1000, isUtc: true)
            .toLocal();
    samples.add(
      PredictAccuracySample(
        day: predictAccuracyDayKey(p.t),
        actualAt: actualAt,
        expectAt:
            DateTime.fromMillisecondsSinceEpoch(expectSec * 1000, isUtc: true)
                .toLocal(),
        hit: trendAccuracySampleIsHit(p),
      ),
    );
  }
  final days = [for (final d in daily) predictAccuracyDayKey(d.t)];
  return predictDailyAccuracyPercents(days: days, samples: samples);
}
