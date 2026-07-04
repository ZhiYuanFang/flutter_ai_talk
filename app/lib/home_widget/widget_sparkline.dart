import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_record_metric.dart';
import '../data/models.dart';
import 'home_widget_payload.dart';

/// 近 7 个自然日（含今天）按 eventId 聚合统计量，供 large 小组件折线。
HomeWidgetSparklinePayload? buildWidgetSparkline({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required String eventId,
  required String colorHex,
  required DateTime now,
}) {
  if (eventId.isEmpty) return null;
  final def = lookupEventById(catalog, eventId);
  final isDuration = def?.parsedEventType == EventCatalogEventType.time;
  final unit = isDuration ? 'hours' : 'count';
  final today = DateTime(now.year, now.month, now.day);
  final points = <double>[];

  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    var sum = 0.0;
    for (final r in history) {
      if (historyRecordEventKey(r) != eventId) continue;
      if (!isHistoryRecordOnLocalDay(r, day)) continue;
      if (historyPayloadInt(r.rawPayload, 'eventNumber') == 0 &&
          historyInstantUnset(parseHistoryInstant(r.rawPayload['endTime']))) {
        continue;
      }
      sum += historyRecordMetric(r);
    }
    points.add(sum);
  }

  return HomeWidgetSparklinePayload(
    eventId: eventId,
    color: colorHex,
    unit: unit,
    points: points,
  );
}
