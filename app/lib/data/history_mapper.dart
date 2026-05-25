import '../api/gateway_json.dart';
import 'event_definition.dart';
import 'history_line_format.dart';
import 'models.dart';

/// 将服务端列表项映射为 [HistoryRecord]；`id` 统一为字符串。
HistoryRecord historyRecordFromServerMap(Map<String, dynamic> j) {
  final idRaw = j['id'];
  final idStr = idRaw == null ? '' : idRaw.toString();
  final eventName = j['eventName'] as String? ?? '';
  final remark = j['remark'] as String? ?? '';
  final action = remark.trim().isEmpty ? '—' : remark.trim();

  final payload = <String, Object?>{};
  for (final e in j.entries) {
    payload[e.key] = e.value;
  }

  final createdAt =
      parseHistoryInstant(j['startTime']) ?? parseHistoryInstant(j['endTime']) ?? DateTime.now();

  return HistoryRecord(
    id: idStr,
    createdAt: createdAt,
    eventName: eventName,
    action: action,
    rawPayload: payload,
  );
}

/// 详情页等展示用时间字符串（`yyyy-MM-dd HH:mm:ss`，本地日历）。
String formatHistoryApiDateTime(DateTime d) {
  String p2(int x) => x.toString().padLeft(2, '0');
  return '${d.year}-${p2(d.month)}-${p2(d.day)} ${p2(d.hour)}:${p2(d.minute)}:${p2(d.second)}';
}

/// 绝对时刻 → **Unix 秒级时间戳**（整型，非毫秒）。
int historyDateTimeToUnixSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

int _unixSecondsFromPayloadField(Object? raw, int fallbackSeconds) {
  if (raw == null) return fallbackSeconds;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  final parsed = parseHistoryInstant(raw);
  if (parsed != null) return historyDateTimeToUnixSeconds(parsed);
  return fallbackSeconds;
}

/// 从 [HistoryRecord.rawPayload] 构造 `POST /device/history/api/event/update` 请求体。
/// `startTime` / `endTime` MUST 为 **Unix 秒级整型**（与列表接口一致，非毫秒、非日期时间字符串）。
/// 若 [clearEndIfNull] 为 `true` 且 [endTime] 为 `null`，则 `endTime` 为 `0`（未结束/清除结束）。
Map<String, dynamic> buildEventUpdateBody({
  required HistoryRecord record,
  required String remark,
  DateTime? startTime,
  DateTime? endTime,
  int? usageCount,
  bool clearEndIfNull = false,
}) {
  final p = record.rawPayload;
  int asInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  final startFallback = historyDateTimeToUnixSeconds(record.createdAt);
  final startOut = startTime != null
      ? historyDateTimeToUnixSeconds(startTime)
      : _unixSecondsFromPayloadField(p['startTime'], startFallback);

  final int endOut;
  if (endTime != null) {
    endOut = historyDateTimeToUnixSeconds(endTime);
  } else if (clearEndIfNull) {
    endOut = 0;
  } else {
    endOut = _unixSecondsFromPayloadField(p['endTime'], 0);
  }

  return {
    'id': asInt(p['id'], fallback: int.tryParse(record.id) ?? 0),
    'deviceNo': readGatewayStr(Map<String, dynamic>.from(p), 'deviceNo', 'device_no') ?? '',
    'eventId': asInt(p['eventId'], fallback: 0),
    'eventName': record.eventName,
    'eventNumber': usageCount ?? asInt(p['eventNumber'], fallback: 0),
    'startTime': startOut,
    'endTime': endOut,
    'remark': remark,
  };
}

/// 由 add 请求体构建乐观 [HistoryRecord]（`id` 通常为 `pending:<uuid>`）。
HistoryRecord historyRecordFromAddBody(Map<String, dynamic> body, {required String id}) {
  final eventName = body['eventName'] as String? ?? '';
  final remark = body['remark'] as String? ?? '';
  final action = remark.trim().isEmpty ? '—' : remark.trim();

  final payload = Map<String, Object?>.from(body);
  final idParsed = int.tryParse(id);
  payload['id'] = idParsed ?? id;

  final createdAt =
      parseHistoryInstant(body['startTime']) ?? parseHistoryInstant(body['endTime']) ?? DateTime.now();

  return HistoryRecord(
    id: id,
    createdAt: createdAt,
    eventName: eventName,
    action: action,
    rawPayload: payload,
  );
}

/// 乐观 pending id（`pending:` 前缀）。
bool isPendingHistoryId(String id) => id.startsWith('pending:');

int _payloadEventId(Map<String, Object?> p) {
  final v = p['eventId'];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int _payloadStartUnix(Map<String, Object?> p) {
  final v = p['startTime'];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// 判断 WS/服务端 record 是否对应当前 pending 乐观行（同 event + startTime）。
bool historyRecordMatchesPendingAdd(HistoryRecord pending, HistoryRecord incoming) {
  if (!isPendingHistoryId(pending.id)) return false;
  final pa = pending.rawPayload;
  final pb = incoming.rawPayload;
  if (_payloadEventId(pa) != _payloadEventId(pb)) return false;
  return _payloadStartUnix(pa) == _payloadStartUnix(pb);
}

/// 构造 `POST /device/history/api/event/add` 请求体（无 `eventUnit`）。
Map<String, dynamic> buildEventAddBody({
  required String deviceNo,
  required EventDefinition event,
  required int eventNumber,
  required DateTime startTime,
  required DateTime endTime,
  String remark = '',
}) {
  return {
    'deviceNo': deviceNo,
    'eventId': int.tryParse(event.id) ?? 0,
    'eventName': event.name,
    'eventNumber': eventNumber,
    'startTime': historyDateTimeToUnixSeconds(startTime),
    'endTime': historyDateTimeToUnixSeconds(endTime),
    'remark': remark,
  };
}
