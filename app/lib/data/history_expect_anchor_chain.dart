import 'appointment_event.dart';
import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
import 'history_mapper.dart';
import 'models.dart';
import 'smart_prediction_rows.dart';
import 'trend_predict_accuracy.dart';

/// 单条 expect-batch 补丁（服务端 id 数字 + 可选 expect*）。
class HistoryExpectPatch {
  const HistoryExpectPatch({
    required this.historyId,
    required this.numericId,
    this.expectStartTime,
    this.expectEndTime,
    this.expectAmount,
  });

  /// [HistoryRecord.id] 字符串形态。
  final String historyId;

  /// expect-batch JSON `id`（number）。
  final int numericId;

  final int? expectStartTime;
  final int? expectEndTime;
  final double? expectAmount;

  /// 指纹：用于 WS 自回声跳过置脏。
  String fingerprint() =>
      '$historyId:$expectStartTime:$expectEndTime:$expectAmount';

  Map<String, dynamic> toJsonItem() {
    final m = <String, dynamic>{'id': numericId};
    if (expectStartTime != null) m['expectStartTime'] = expectStartTime;
    if (expectEndTime != null) m['expectEndTime'] = expectEndTime;
    if (expectAmount != null) m['expectAmount'] = expectAmount;
    return m;
  }
}

/// 同桶「前一条 tip → predictNext → 本条 stamp」；跳过预约桶；桶首省略。
List<HistoryExpectPatch> buildHistoryExpectAnchorPatches({
  required List<HistoryRecord> snapshot,
  required List<EventDefinition> catalog,
  required DateTime now,
  required int halfLifeDays,
}) {
  // 按预测桶分组（跳过回忆种子 / pending / 无数字 id）
  final byBucket = <String, List<HistoryRecord>>{};
  for (final r in snapshot) {
    if (isPredictionRecallSeedRecord(r)) continue;
    if (isPendingHistoryId(r.id)) continue;
    final eventId = historyRecordEventId(r);
    if (eventId.isEmpty) continue;
    final bucket = predictionBucketKeyForEventId(
      eventId: eventId,
      catalog: catalog,
    );
    if (bucket.isEmpty) continue;
    (byBucket[bucket] ??= <HistoryRecord>[]).add(r);
  }

  final patches = <HistoryExpectPatch>[];
  for (final e in byBucket.entries) {
    final bucketKey = e.key;
    final root = catalogRootIdFor(catalog, bucketKey);
    // 预约根：不做 interval expect-batch
    if (catalogRootIsAppointment(root, catalog)) continue;

    final rows = List<HistoryRecord>.from(e.value);
    rows.sort((a, b) {
      final ta = occurrenceInstant(a, includeActive: true) ?? a.createdAt;
      final tb = occurrenceInstant(b, includeActive: true) ?? b.createdAt;
      final c = ta.compareTo(tb);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });

    final def = lookupEventById(catalog, bucketKey) ??
        lookupEventById(catalog, root);
    final eventName = def?.name ?? rows.first.eventName;
    final colorHex = def?.colorRaw ?? '#5BA3E8';

    for (var i = 0; i < rows.length; i++) {
      // 桶首无前驱 → 省略 expect
      if (i == 0) continue;
      final target = rows[i];
      final numericId = int.tryParse(target.id);
      if (numericId == null || numericId <= 0) continue;

      // 仅用本条之前的发生序列作 tip 锚点
      final prior = rows.sublist(0, i);
      var pred = predictNextForEventKey(
        eventKey: bucketKey,
        eventName: eventName,
        records: prior,
        now: now,
        halfLifeDays: halfLifeDays,
        colorHex: colorHex,
        includeActive: true,
      );
      if (pred == null) continue;
      pred = attachWinningExpect(
        prediction: pred,
        records: prior,
        catalog: catalog,
        now: now,
        halfLifeDays: halfLifeDays,
      );
      final stamp = HistoryExpectStamp.fromPrediction(pred);
      if (stamp == null || stamp.isEmpty) continue;

      // 与当前 rawPayload 相同则可不发
      if (_expectStampMatchesPayload(target.rawPayload, stamp)) continue;

      patches.add(
        HistoryExpectPatch(
          historyId: target.id,
          numericId: numericId,
          expectStartTime: stamp.expectStartTime,
          expectEndTime: stamp.expectEndTime,
          expectAmount: stamp.expectAmount,
        ),
      );
    }
  }
  return patches;
}

bool _expectStampMatchesPayload(
  Map<String, Object?> p,
  HistoryExpectStamp stamp,
) {
  final start = expectStartTimeSecFromPayload(p);
  final end = expectEndTimeSecFromPayload(p);
  final amt = expectAmountFromPayload(p);
  if (start != stamp.expectStartTime) return false;
  if (end != stamp.expectEndTime) return false;
  if (amt == null && stamp.expectAmount == null) return true;
  if (amt == null || stamp.expectAmount == null) return false;
  return (amt - stamp.expectAmount!).abs() < 1e-6;
}
