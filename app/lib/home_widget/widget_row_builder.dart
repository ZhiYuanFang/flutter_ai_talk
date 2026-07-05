import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import 'home_widget_payload.dart';

enum HomeWidgetKind {
  small,
  medium,
  large;

  String get wireValue => name;
}

HomeWidgetKind homeWidgetKindFromWire(String? raw) {
  switch (raw?.trim()) {
    case 'medium':
      return HomeWidgetKind.medium;
    case 'large':
      return HomeWidgetKind.large;
    default:
      return HomeWidgetKind.small;
  }
}

class WidgetActiveRowModel {
  const WidgetActiveRowModel({
    required this.eventId,
    required this.name,
    required this.startAt,
    required this.colorHex,
  });

  final String eventId;
  final String name;
  final DateTime startAt;
  final String colorHex;

  HomeWidgetRowPayload toPayload() => HomeWidgetRowPayload(
        kind: 'active',
        eventId: eventId,
        name: name,
        startAt: HomeWidgetRowPayload.isoUtc(startAt),
        color: colorHex,
      );
}

List<WidgetActiveRowModel> collectActiveTimingRows(
  List<HistoryRecord> history, {
  List<EventDefinition> catalog = const [],
}) {
  final rows = <WidgetActiveRowModel>[];
  for (final r in history) {
    if (!isActiveTimingRecord(r)) continue;
    final id = historyRecordEventKey(r);
    final def = lookupEventById(catalog, id);
    rows.add(
      WidgetActiveRowModel(
        eventId: id,
        name: r.eventName.trim().isEmpty ? '未知事件' : r.eventName.trim(),
        startAt: activeTimingStartAt(r),
        colorHex: colorHexFromEvent(def),
      ),
    );
  }
  rows.sort((a, b) => a.startAt.compareTo(b.startAt));
  return rows;
}

/// v3：hero 仅 top-1 predict，不含进行中计时。
HomeWidgetRowPayload? buildWidgetHero({
  required List<EventNextPrediction> predictions,
  required DateTime now,
}) {
  if (predictions.isEmpty) return null;
  final p = predictions.first;
  return HomeWidgetRowPayload(
    kind: 'predict',
    eventId: p.eventId,
    name: p.eventName,
    nextAt: HomeWidgetRowPayload.isoUtc(p.nextAt),
    status: p.isOverdue(now) ? 'overdue' : 'upcoming',
    color: p.colorHex,
  );
}

/// v3：上次记录 top-N predict 的 lastAt。
List<HomeWidgetRowPayload> buildWidgetRecentLast({
  required List<EventNextPrediction> predictions,
  int count = 3,
}) {
  return predictions.take(count).map((p) {
    return HomeWidgetRowPayload(
      kind: 'recent',
      eventId: p.eventId,
      name: p.eventName,
      lastAt:  HomeWidgetRowPayload.isoUtc(p.lastAt),
      color: p.colorHex,
    );
  }).toList();
}

/// 兼容 App 内预览列表（仍展示 active + predict 行）。
List<HomeWidgetRowPayload> buildWidgetRows({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required List<EventNextPrediction> predictions,
  required HomeWidgetKind kind,
  required DateTime now,
}) {
  final hero = buildWidgetHero(predictions: predictions, now: now);
  if (kind == HomeWidgetKind.small) {
    return hero != null ? [hero] : const [];
  }
  if (kind == HomeWidgetKind.medium) {
    return buildWidgetRecentLast(predictions: predictions);
  }
  final out = <HomeWidgetRowPayload>[];
  if (hero != null) out.add(hero);
  out.addAll(buildWidgetRecentLast(predictions: predictions));
  return out;
}
