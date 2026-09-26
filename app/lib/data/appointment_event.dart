import 'active_timing_stop.dart';
import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';

/// 将任意 catalog id 解析为预约读写用的根 eventId。
String appointmentRootEventId(String eventId, List<EventDefinition> catalog) {
  return rootEventIdForCatalog(eventId, catalog);
}

/// 某根（或其子树任一节点标了 isAppointment）是否按预约事件处理。
bool catalogRootIsAppointment(
  String rootEventId,
  List<EventDefinition> catalog,
) {
  final root = rootEventId.trim();
  if (root.isEmpty) return false;
  final rootDef = lookupEventById(catalog, root);
  if (rootDef?.isAppointment == true) return true;
  for (final e in catalog) {
    if (!e.isAppointment || e.id.isEmpty) continue;
    final r = rootEventIdForCatalog(e.id, catalog);
    if (r == root || catalogIdsEqual(r, root)) return true;
  }
  return false;
}

/// [event] 所属根是否为预约事件。
bool eventIsAppointment(EventDefinition event, List<EventDefinition> catalog) {
  final root = appointmentRootEventId(event.id, catalog);
  return catalogRootIsAppointment(root, catalog);
}

/// unix 秒 → 本地 DateTime；`<=0` 返回 null。
DateTime? appointmentNextAtFromSec(int sec) {
  if (sec < 1) return null;
  return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true).toLocal();
}

/// 本地 DateTime → unix 秒。
int appointmentNextAtToSec(DateTime local) {
  return local.toUtc().millisecondsSinceEpoch ~/ 1000;
}

/// `nextAtSec==0` 或早于 [now] 视为需引导补约。
bool appointmentNextAtEmptyOrOverdue(int nextAtSec, DateTime now) {
  if (nextAtSec < 1) return true;
  final t = appointmentNextAtFromSec(nextAtSec);
  if (t == null) return true;
  return !t.isAfter(now);
}
