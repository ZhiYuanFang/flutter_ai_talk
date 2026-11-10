import 'event_branding.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart' show formatExpectDurationFromSec;
import 'history_line_format.dart';
import 'history_mapper.dart';
import 'models.dart';
import 'relative_calendar_day.dart';

/// 开始时刻满分窗：|实际 − 预计| ≤ 30 分钟 → S_time=100。
const kPredictAccuracyHitWindowSec = 1800;

/// 开始时刻零分界：≥ 120 分钟 → S_time=0。
const kPredictAccuracyTimeZeroSec = 7200;

/// 量相对误差 ≥ 此值 → S_qty=0。
const kPredictAccuracyQtyZeroRelErr = 0.5;

/// 时间对齐权重。
const kPredictAccuracyTimeWeight = 0.7;

/// 量对齐权重。
const kPredictAccuracyQtyWeight = 0.3;

/// 绿档合成分下限。
const kPredictAccuracyScoreGreen = 70.0;

/// 黄档合成分下限（低于此为红）。
const kPredictAccuracyScoreYellow = 40.0;

/// 自然日键（本地年月日 0 点）。
DateTime predictAccuracyDayKey(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// 从 payload 读正 unix 秒字段；不可用 → null。
int? _positiveUnixSecFromPayload(Map<String, Object?> p, String key) {
  final v = p[key];
  if (v is int) return v > 0 ? v : null;
  if (v is num) {
    final i = v.toInt();
    return i > 0 ? i : null;
  }
  final parsed = int.tryParse(v?.toString() ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

/// 从 payload 读正 expectStartTime（unix 秒）；不可用 → null（不计样本、禁止重放）。
int? expectStartTimeSecFromPayload(Map<String, Object?> p) =>
    _positiveUnixSecFromPayload(p, 'expectStartTime');

int? expectEndTimeSecFromPayload(Map<String, Object?> p) =>
    _positiveUnixSecFromPayload(p, 'expectEndTime');

/// 正 expectAmount；不可用 → null。
double? expectAmountFromPayload(Map<String, Object?> p) {
  final v = p['expectAmount'];
  if (v is num) {
    final d = v.toDouble();
    return d > 0 ? d : null;
  }
  final parsed = double.tryParse(v?.toString() ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

/// 绿 / 黄 / 红（合成分分档）。
enum PredictAccuracyTraffic {
  green,
  yellow,
  red,
}

PredictAccuracyTraffic predictAccuracyTrafficForScore(double score) {
  if (score >= kPredictAccuracyScoreGreen) return PredictAccuracyTraffic.green;
  if (score >= kPredictAccuracyScoreYellow) {
    return PredictAccuracyTraffic.yellow;
  }
  return PredictAccuracyTraffic.red;
}

/// 历史行预计开始（本地）；无可用 expectStartTime → null。
DateTime? historyRecordExpectStartAt(HistoryRecord r) {
  final expectSec = expectStartTimeSecFromPayload(r.rawPayload);
  if (expectSec == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(expectSec * 1000, isUtc: true)
      .toLocal();
}

/// 仅开始时刻红档（忽略量/合成分）；无 expect / 回忆种子 → false。
bool historyRecordStartTimeMissIsRed(HistoryRecord r) {
  if (r.rawPayload['_predictionRecallSeed'] == true) return false;
  final expectSec = expectStartTimeSecFromPayload(r.rawPayload);
  if (expectSec == null) return false;
  final actualAt =
      parseHistoryInstant(r.rawPayload['startTime']) ?? r.createdAt;
  final actualSec = historyDateTimeToUnixSeconds(actualAt);
  if (actualSec <= 0) return false;
  final timeScore = predictAccuracyTimeScore(
    absDiffSec: (actualSec - expectSec).abs(),
  );
  return predictAccuracyTrafficForScore(timeScore) ==
      PredictAccuracyTraffic.red;
}

/// 喂养页学习条全文；非红档或无预计 → null。
String? formatHistoryRedTimeMissLearningLabel(
  HistoryRecord r,
  DateTime now,
) {
  if (!historyRecordStartTimeMissIsRed(r)) return null;
  final expectAt = historyRecordExpectStartAt(r);
  if (expectAt == null) return null;
  final xx = formatRelativeCalendarDayAndTime(
    expectAt,
    now,
    omitDayWhenToday: true,
  );
  return '预计${xx}发生，本次记录偏差过大，正按照宝宝的喂养节奏，个性化学习中';
}

/// S_time：≤30min→100；≥120min→0；中间线性。
double predictAccuracyTimeScore({required int absDiffSec}) {
  final d = absDiffSec < 0 ? -absDiffSec : absDiffSec;
  if (d <= kPredictAccuracyHitWindowSec) return 100;
  if (d >= kPredictAccuracyTimeZeroSec) return 0;
  final span = kPredictAccuracyTimeZeroSec - kPredictAccuracyHitWindowSec;
  return 100.0 *
      (1.0 - (d - kPredictAccuracyHitWindowSec) / span);
}

/// S_qty：相对误差 0→100；≥0.5→0；中间线性。
double predictAccuracyQtyScore({
  required double expect,
  required double actual,
}) {
  final denom = expect.abs() < 1e-9 ? 1e-9 : expect.abs();
  final err = (actual - expect).abs() / denom;
  if (err <= 0) return 100;
  if (err >= kPredictAccuracyQtyZeroRelErr) return 0;
  return 100.0 * (1.0 - err / kPredictAccuracyQtyZeroRelErr);
}

/// 合成分：有量 0.7/0.3；缺量 = 纯时间。
double predictAccuracyCompositeScore({
  required double timeScore,
  double? qtyScore,
}) {
  if (qtyScore == null) return timeScore.clamp(0, 100);
  return (kPredictAccuracyTimeWeight * timeScore +
          kPredictAccuracyQtyWeight * qtyScore)
      .clamp(0, 100);
}

String _formatAmountNumber(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  final s = value.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// 单条合格准确率样本（预计 vs 实际 + 可选量维）。
class PredictAccuracySample {
  const PredictAccuracySample({
    required this.day,
    required this.actualAt,
    required this.expectAt,
    required this.score,
    this.expectQtyLabel,
    this.actualQtyLabel,
  });

  /// 实际发生所在自然日
  final DateTime day;

  /// 实际开始
  final DateTime actualAt;

  /// 预计开始（来自已存 expectStartTime）
  final DateTime expectAt;

  /// 合成分 0–100
  final double score;

  /// 预计量文案（用量或时长）；一次性/无量维为 null
  final String? expectQtyLabel;

  /// 实际量文案
  final String? actualQtyLabel;

  /// 兼容旧二元语义（合成分 ≥ 绿档）
  bool get hit => score >= kPredictAccuracyScoreGreen;

  PredictAccuracyTraffic get traffic =>
      predictAccuracyTrafficForScore(score);

  int get scorePercent => score.round().clamp(0, 100);
}

/// 历史行 → 合格样本；无 expectStart / 回忆种子 → 跳过（禁止重放）。
PredictAccuracySample? predictAccuracySampleFromRecord(
  HistoryRecord r, {
  List<EventDefinition> catalog = const [],
}) {
  if (r.rawPayload['_predictionRecallSeed'] == true) return null;
  final expectSec = expectStartTimeSecFromPayload(r.rawPayload);
  if (expectSec == null) return null;
  final actualAt =
      parseHistoryInstant(r.rawPayload['startTime']) ?? r.createdAt;
  final actualSec = historyDateTimeToUnixSeconds(actualAt);
  if (actualSec <= 0) return null;

  final timeScore = predictAccuracyTimeScore(
    absDiffSec: (actualSec - expectSec).abs(),
  );

  // 一次性：不展示量、不计 S_qty
  final leafType = catalog.isEmpty
      ? null
      : lookupEventForRecord(catalog, r)?.parsedEventType;
  final isOneShot = leafType == EventCatalogEventType.one;

  String? expectQtyLabel;
  String? actualQtyLabel;
  double? qtyScore;

  if (!isOneShot) {
    final expectAmt = expectAmountFromPayload(r.rawPayload);
    final actualAmt = () {
      final n = historyPayloadInt(r.rawPayload, 'eventNumber');
      if (n > 0) return n.toDouble();
      return null;
    }();
    if (expectAmt != null && actualAmt != null) {
      final unit = (r.rawPayload['eventUnit'] as String?)?.trim() ??
          (r.rawPayload['event_unit'] as String?)?.trim() ??
          '';
      expectQtyLabel = '${_formatAmountNumber(expectAmt)}$unit';
      actualQtyLabel = '${_formatAmountNumber(actualAmt)}$unit';
      qtyScore = predictAccuracyQtyScore(
        expect: expectAmt,
        actual: actualAmt,
      );
    } else {
      // 时长进量槽：有 expectEnd 与实际结束
      final expectEnd = expectEndTimeSecFromPayload(r.rawPayload);
      final endAt = parseHistoryInstant(r.rawPayload['endTime']);
      if (expectEnd != null &&
          endAt != null &&
          !historyInstantUnset(endAt) &&
          endAt.isAfter(actualAt)) {
        final expectDur = expectEnd - expectSec;
        final actualDur = endAt.difference(actualAt).inSeconds;
        if (expectDur > 0 && actualDur > 0) {
          expectQtyLabel = formatExpectDurationFromSec(expectDur);
          actualQtyLabel = formatExpectDurationFromSec(actualDur);
          qtyScore = predictAccuracyQtyScore(
            expect: expectDur.toDouble(),
            actual: actualDur.toDouble(),
          );
        }
      }
    }
  }

  final score = predictAccuracyCompositeScore(
    timeScore: timeScore,
    qtyScore: qtyScore,
  );

  return PredictAccuracySample(
    day: predictAccuracyDayKey(actualAt),
    actualAt: actualAt.toLocal(),
    expectAt: DateTime.fromMillisecondsSinceEpoch(expectSec * 1000, isUtc: true)
        .toLocal(),
    score: score,
    expectQtyLabel: expectQtyLabel,
    actualQtyLabel: actualQtyLabel,
  );
}

/// 从历史列表收集合格样本（不重放）。
List<PredictAccuracySample> predictAccuracySamplesFromHistory(
  Iterable<HistoryRecord> records, {
  List<EventDefinition> catalog = const [],
}) {
  final out = <PredictAccuracySample>[];
  for (final r in records) {
    final s = predictAccuracySampleFromRecord(r, catalog: catalog);
    if (s != null) out.add(s);
  }
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

/// 与 [days] 等长；日 % = 当日合成分均值四舍五入；无样本 → null。
List<int?> predictDailyAccuracyPercents({
  required List<DateTime> days,
  required List<PredictAccuracySample> samples,
}) {
  if (days.isEmpty) return const [];
  final sums = <DateTime, double>{};
  final counts = <DateTime, int>{};
  for (final s in samples) {
    final key = predictAccuracyDayKey(s.day);
    sums[key] = (sums[key] ?? 0) + s.score;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return [
    for (final d in days)
      () {
        final key = predictAccuracyDayKey(d);
        final n = counts[key] ?? 0;
        if (n < 1) return null;
        return ((sums[key] ?? 0) / n).round().clamp(0, 100);
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

// --- 对照图区空态示例（仅 UI 内存；禁止写入 history / pending） ---

int _predictAccuracySampleHash(String seed) {
  var h = 0x9e3779b9;
  for (final c in seed.codeUnits) {
    h = 0x1fffffff & (h * 31 + c);
  }
  return h.abs();
}

/// 示例近 N 日准确率 %（非 null；相邻日故意高低差）。
List<int> predictAccuracySamplePercents({
  required String eventId,
  required int dayCount,
}) {
  final n = dayCount < 1 ? 1 : dayCount;
  var h = _predictAccuracySampleHash(eventId.trim());
  final out = <int>[];
  var prev = 60;
  for (var i = 0; i < n; i++) {
    h = 0x1fffffff & (h * 31 + i + 17);
    var next = i.isEven ? (72 + (h % 24)) : (45 + (h % 20));
    if ((next - prev).abs() < 15) {
      next = prev >= 70 ? (prev - 18).clamp(45, 95) : (prev + 18).clamp(45, 95);
    }
    out.add(next);
    prev = next;
  }
  return out;
}

PredictAccuracySample _sampleRow({
  required DateTime day,
  required DateTime expectAt,
  required int deltaMin,
  String? expectQty,
  String? actualQty,
  double? qtyScoreOverride,
}) {
  final actualAt = expectAt.add(Duration(minutes: deltaMin));
  final timeScore = predictAccuracyTimeScore(
    absDiffSec: deltaMin.abs() * 60,
  );
  final score = predictAccuracyCompositeScore(
    timeScore: timeScore,
    qtyScore: qtyScoreOverride,
  );
  return PredictAccuracySample(
    day: day,
    actualAt: actualAt,
    expectAt: expectAt,
    score: score,
    expectQtyLabel: expectQty,
    actualQtyLabel: actualQty,
  );
}

/// 示例某日「预计→实际」行（内存；不写库）。
/// [oneShot] 为 true 时不含量段（一次性）。
List<PredictAccuracySample> predictAccuracySampleRowsForDay({
  required String eventId,
  required DateTime day,
  bool oneShot = false,
}) {
  final d = predictAccuracyDayKey(day);
  final h = _predictAccuracySampleHash(
    '${eventId.trim()}|${d.year}-${d.month}-${d.day}',
  );
  final hour = 8 + (h % 10);
  final expect1 = DateTime(d.year, d.month, d.day, hour, 10);
  final tight1 = h.isEven;
  final rows = <PredictAccuracySample>[
    _sampleRow(
      day: d,
      expectAt: expect1,
      deltaMin: tight1 ? 8 : 42,
      expectQty: oneShot ? null : '120ml',
      actualQty: oneShot ? null : (tight1 ? '118ml' : '90ml'),
      qtyScoreOverride: oneShot
          ? null
          : (tight1 ? 96.0 : 40.0),
    ),
  ];
  if (h % 3 != 0) {
    final expect2 = expect1.add(const Duration(hours: 4, minutes: 20));
    final tight2 = !tight1;
    rows.add(
      _sampleRow(
        day: d,
        expectAt: expect2,
        deltaMin: tight2 ? 5 : 48,
        expectQty: oneShot ? null : '15分钟',
        actualQty: oneShot ? null : (tight2 ? '14分钟' : '28分钟'),
        qtyScoreOverride: oneShot
            ? null
            : (tight2 ? 90.0 : 20.0),
      ),
    );
  }
  return rows;
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
    final timeScore = predictAccuracyTimeScore(
      absDiffSec: (actualSec - expectSec).abs(),
    );
    samples.add(
      PredictAccuracySample(
        day: predictAccuracyDayKey(p.t),
        actualAt: actualAt,
        expectAt:
            DateTime.fromMillisecondsSinceEpoch(expectSec * 1000, isUtc: true)
                .toLocal(),
        score: timeScore,
      ),
    );
  }
  final days = [for (final d in daily) predictAccuracyDayKey(d.t)];
  return predictDailyAccuracyPercents(days: days, samples: samples);
}
