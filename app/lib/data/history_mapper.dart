import '../api/gateway_json.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
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
  int? postId,
  int? mediaType,
  List<String>? imageKeys,
  String? videoKey,
  bool patchMediaFields = false,
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

  final body = {
    'id': asInt(p['id'], fallback: int.tryParse(record.id) ?? 0),
    'deviceNo': readGatewayStr(Map<String, dynamic>.from(p), 'deviceNo', 'device_no') ?? '',
    'eventId': asInt(p['eventId'], fallback: 0),
    'eventName': record.eventName,
    'eventNumber': usageCount ?? asInt(p['eventNumber'], fallback: 0),
    'startTime': startOut,
    'endTime': endOut,
    'remark': remark,
  };
  if (patchMediaFields) {
    body['postId'] = postId ?? historyPayloadPostId(p);
    body['mediaType'] = mediaType ?? historyPayloadMediaType(p);
    body['imageKeys'] = imageKeys ?? historyPayloadImageKeys(p);
    body['videoKey'] = videoKey ?? historyPayloadVideoKey(p);
  } else {
    if (postId != null) body['postId'] = postId;
    if (mediaType != null) body['mediaType'] = mediaType;
    if (imageKeys != null) body['imageKeys'] = imageKeys;
    if (videoKey != null) body['videoKey'] = videoKey;
  }
  return body;
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

int historyPayloadPostId(Map<String, Object?> p) {
  final v = p['postId'];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

List<String> historyPayloadImageKeys(Map<String, Object?> p) {
  final raw = p['imageKeys'];
  if (raw is! List) return const [];
  return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
}

String historyPayloadVideoKey(Map<String, Object?> p) {
  final v = p['videoKey'];
  return v?.toString().trim() ?? '';
}

int historyPayloadMediaType(Map<String, Object?> p) {
  final v = p['mediaType'];
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

int _payloadIntField(Map<String, Object?> p, String key, {int fallback = 0}) {
  final v = p[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

/// Add 可选打戳（对齐 Go `*int64`/`*float64` omitempty）；缺维不写键、不写 0。
class HistoryExpectStamp {
  const HistoryExpectStamp({
    this.expectStartTime,
    this.expectEndTime,
    this.expectAmount,
  });

  /// 预计开始：unix 秒
  final int? expectStartTime;

  /// 预计结束：unix 秒（start + duration）
  final int? expectEndTime;

  /// 预计用量：浮点，禁止 toInt 截断
  final double? expectAmount;

  bool get isEmpty =>
      expectStartTime == null && expectEndTime == null && expectAmount == null;

  /// 从 [EventNextPrediction] 打戳：nextAt→start（含过期）；duration→end；amount 浮点。
  /// 无 pred 返回 null；缺维字段为 null（调用方省略键）。
  static HistoryExpectStamp? fromPrediction(EventNextPrediction? pred) {
    if (pred == null) return null;
    // 预计开始：预报 nextAt（过期仍打）
    final start = historyDateTimeToUnixSeconds(pred.nextAt);
    // 有正 duration 才算预计结束
    final dur = pred.expectDurationSec;
    final end = (dur != null && dur > 0) ? start + dur : null;
    // 正 amount 才上传；禁止 toInt
    final amt = pred.expectAmount;
    final amount = (amt != null && amt > 0) ? amt : null;
    return HistoryExpectStamp(
      expectStartTime: start,
      expectEndTime: end,
      expectAmount: amount,
    );
  }
}

/// 将非 null expect* 写入 body（不写 0 占位）。
void applyHistoryExpectStamp(Map<String, dynamic> body, HistoryExpectStamp? stamp) {
  if (stamp == null || stamp.isEmpty) return;
  final start = stamp.expectStartTime;
  if (start != null) body['expectStartTime'] = start;
  final end = stamp.expectEndTime;
  if (end != null) body['expectEndTime'] = end;
  final amount = stamp.expectAmount;
  if (amount != null) body['expectAmount'] = amount;
}

/// 从 payload 透传已有 expect*（pending flush）；amount 保留 double。
void _copyExpectFieldsFromPayload(Map<String, dynamic> body, Map<String, Object?> p) {
  final start = p['expectStartTime'];
  if (start is int) {
    body['expectStartTime'] = start;
  } else if (start is num) {
    body['expectStartTime'] = start.toInt();
  }
  final end = p['expectEndTime'];
  if (end is int) {
    body['expectEndTime'] = end;
  } else if (end is num) {
    body['expectEndTime'] = end.toInt();
  }
  final amount = p['expectAmount'];
  if (amount is double) {
    body['expectAmount'] = amount;
  } else if (amount is num) {
    body['expectAmount'] = amount.toDouble();
  }
}

/// 从 pending 乐观行 `rawPayload` 构造 add 请求体（无 `eventUnit`）。
Map<String, dynamic> buildEventAddBodyFromPendingRecord(HistoryRecord pending) {
  final p = pending.rawPayload;
  final body = <String, dynamic>{
    'deviceNo': readGatewayStr(Map<String, dynamic>.from(p), 'deviceNo', 'device_no') ?? '',
    'eventId': _payloadIntField(p, 'eventId'),
    'eventName': pending.eventName,
    'eventNumber': _payloadIntField(p, 'eventNumber'),
    'startTime': _payloadIntField(p, 'startTime'),
    'endTime': _payloadIntField(p, 'endTime'),
    'remark': p['remark']?.toString() ?? '',
  };
  // pending 行若已带 expect*，flush 时原样带上
  _copyExpectFieldsFromPayload(body, p);
  return body;
}

/// 过滤 `pending:*` 行并保持原列表顺序。
List<HistoryRecord> listPendingAddsInOrder(List<HistoryRecord> items) {
  return items.where((e) => isPendingHistoryId(e.id)).toList(growable: false);
}

/// 远端第一页与本地 pending 合并：保留尚未 flush 的 `pending:*`（追加在末尾）。
List<HistoryRecord> mergeRemoteHistoryAscWithPendingLocal({
  required List<HistoryRecord> remoteAsc,
  required List<HistoryRecord> localItems,
}) {
  final remoteIds = remoteAsc.map((e) => e.id).toSet();
  final pending = listPendingAddsInOrder(localItems)
      .where((p) => !remoteIds.contains(p.id))
      .toList(growable: false);
  if (pending.isEmpty) return remoteAsc;
  return [...remoteAsc, ...pending];
}

/// page1 upsert + 保留本地不在 page1 的更旧 id + pending（resume/bootstrap 用）。
List<HistoryRecord> mergeRemotePage1PreservingLocalDepth({
  required List<HistoryRecord> remoteAsc,
  required List<HistoryRecord> localItems,
}) {
  final remoteIds = remoteAsc.map((e) => e.id).toSet();
  // 更深页：非 pending 且本轮 page1 未返回的本地行
  final olderKept = <HistoryRecord>[
    for (final e in localItems)
      if (!remoteIds.contains(e.id) && !isPendingHistoryId(e.id)) e,
  ];
  final pending = listPendingAddsInOrder(localItems)
      .where((p) => !remoteIds.contains(p.id))
      .toList(growable: false);
  final core = <HistoryRecord>[...olderKept, ...remoteAsc]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  if (pending.isEmpty) return core;
  return [...core, ...pending];
}

/// 构造 `POST /device/history/api/event/add` 请求体（无 `eventUnit`）。
/// [expect] 仅 add 打戳；update/stop MUST NOT 传入。
Map<String, dynamic> buildEventAddBody({
  required String deviceNo,
  required EventDefinition event,
  required int eventNumber,
  required DateTime startTime,
  required DateTime endTime,
  String remark = '',
  HistoryExpectStamp? expect,
}) {
  final body = <String, dynamic>{
    'deviceNo': deviceNo,
    'eventId': int.tryParse(event.id) ?? 0,
    'eventName': event.name,
    'eventNumber': eventNumber,
    'startTime': historyDateTimeToUnixSeconds(startTime),
    'endTime': historyDateTimeToUnixSeconds(endTime),
    'remark': remark,
  };
  applyHistoryExpectStamp(body, expect);
  return body;
}
