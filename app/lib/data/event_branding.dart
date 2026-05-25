import 'event_definition.dart';
import 'models.dart';

/// 历史记录上的 `eventId`（字符串）。
String historyRecordEventId(HistoryRecord record) {
  final raw = record.rawPayload['eventId'];
  if (raw == null) return '';
  return raw.toString().trim();
}

/// 主页历史分组键：非空 `eventId` 优先，否则 `eventName.trim()`。
String historyRecordEventKey(HistoryRecord record) {
  final id = historyRecordEventId(record);
  if (id.isNotEmpty) return id;
  return record.eventName.trim();
}

/// 在目录中查找与记录对应的事件定义。
EventDefinition? lookupEventForRecord(
  List<EventDefinition> catalog,
  HistoryRecord record,
) {
  final id = historyRecordEventId(record);
  if (id.isNotEmpty) {
    for (final e in catalog) {
      if (e.id == id) return e;
    }
  }
  final name = record.eventName.trim();
  if (name.isEmpty) return null;
  EventDefinition? match;
  for (final e in catalog) {
    if (e.name.trim() == name) {
      if (match != null) return null;
      match = e;
    }
  }
  return match;
}

EventDefinition? lookupEventById(
  List<EventDefinition> catalog,
  String eventId,
) {
  final key = eventId.trim();
  if (key.isEmpty) return null;
  for (final e in catalog) {
    if (e.id == key) return e;
  }
  return null;
}
