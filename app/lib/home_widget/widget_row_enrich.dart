import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import 'home_widget_payload.dart';
import 'widget_logo_cache.dart';

/// 为 payload 行补充 catalog 色与本地 logo 路径。
Future<List<HomeWidgetRowPayload>> enrichWidgetRows(
  List<HomeWidgetRowPayload> rows,
  List<EventDefinition> catalog,
) async {
  final out = <HomeWidgetRowPayload>[];
  for (final row in rows) {
    out.add(await enrichWidgetRow(row, catalog));
  }
  return out;
}

Future<HomeWidgetRowPayload> enrichWidgetRow(
  HomeWidgetRowPayload row,
  List<EventDefinition> catalog,
) async {
  final def = lookupEventById(catalog, row.eventId);
  final logo = await widgetLogoFileForEvent(def);
  return HomeWidgetRowPayload(
    kind: row.kind,
    eventId: row.eventId,
    name: row.name,
    startAt: row.startAt,
    nextAt: row.nextAt,
    lastAt: row.lastAt,
    status: row.status,
    color: row.color.isNotEmpty ? row.color : colorHexFromEvent(def),
    logoFile: logo,
  );
}
