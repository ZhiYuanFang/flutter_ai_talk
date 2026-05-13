import '../api/gateway_json.dart';
import 'models.dart';

/// 将服务端列表项映射为 [HistoryRecord]；`id` 统一为字符串。
HistoryRecord historyRecordFromServerMap(Map<String, dynamic> j) {
  final idRaw = j['id'];
  final idStr = idRaw == null ? '' : idRaw.toString();
  final eventName = j['eventName'] as String? ?? '';
  final numVal = j['eventNumber'];
  final unit = j['eventUnit'] as String? ?? '';
  final remark = j['remark'] as String? ?? '';
  final numStr = numVal == null ? '' : numVal.toString();
  final actionParts = <String>[];
  if (numStr.isNotEmpty || unit.isNotEmpty) {
    actionParts.add('$numStr$unit'.trim());
  }
  if (remark.isNotEmpty) actionParts.add(remark);
  final action = actionParts.isEmpty ? '—' : actionParts.join(' ');

  DateTime _parseTime(Object? raw) {
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true).toLocal();
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt() * 1000, isUtc: true).toLocal();
    }
    if (raw is String && raw.isNotEmpty) {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      return DateTime.tryParse(normalized) ?? DateTime.now();
    }
    return DateTime.now();
  }

  final startRaw = j['startTime'] ?? j['endTime'];
  final createdAt = _parseTime(startRaw);

  final payload = <String, Object?>{};
  for (final e in j.entries) {
    payload[e.key] = e.value;
  }

  return HistoryRecord(
    id: idStr,
    createdAt: createdAt,
    eventName: eventName,
    action: action,
    rawPayload: payload,
  );
}

/// 从 [HistoryRecord.rawPayload] 构造更新接口 body（编辑后合并表单上的 eventName / action→remark）。
Map<String, dynamic> buildEventUpdateBody({
  required HistoryRecord record,
  required String editedEventName,
  required String editedAction,
}) {
  final p = record.rawPayload;
  int asInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  return {
    'id': asInt(p['id'], fallback: int.tryParse(record.id) ?? 0),
    'deviceNo': readGatewayStr(Map<String, dynamic>.from(p), 'deviceNo', 'device_no') ?? '',
    'eventId': asInt(p['eventId'], fallback: 0),
    'eventName': editedEventName,
    'eventUnit': (p['eventUnit'] as String?) ?? '',
    'eventNumber': asInt(p['eventNumber'], fallback: 0),
    'startTime': (p['startTime'] as String?) ?? record.createdAt.toIso8601String().split('T').first.replaceAll('T', ' '),
    'endTime': (p['endTime'] as String?) ?? '',
    'remark': editedAction,
  };
}
