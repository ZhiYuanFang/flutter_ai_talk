import '../api/api_client.dart';
import '../api/app_debug_log.dart';
import '../api/gateway_json.dart';
import 'smart_prediction_rows.dart';

/// `GET /device/history/api/event/latest-by-event` 单条。
class HistoryLatestByEventItem {
  const HistoryLatestByEventItem({
    required this.eventId,
    required this.occurredAt,
    this.remark = '',
    this.historyId,
  });

  final String eventId;
  final DateTime occurredAt;
  final String remark;
  final String? historyId;

  PredictionLastOccurrenceRef toLastRef() => PredictionLastOccurrenceRef(
        at: occurredAt,
        remark: remark,
      );
}

/// 批量最近发生（纯 history；含未闭合；不含 appointment_next）。
class HistoryLatestByEventRepository {
  HistoryLatestByEventRepository(this._api);

  final ApiClient _api;

  /// 失败返回 null（不 Toast）；成功可为空 map。
  Future<Map<String, HistoryLatestByEventItem>?> fetchLatestByEvent({
    required String deviceNo,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return null;
    try {
      final data = await _api.getEnvelope(
        '/device/history/api/event/latest-by-event',
        query: {'deviceNo': dn},
        timeout: const Duration(seconds: 45),
      );
      if (data == null) return null;
      final list = data['list'] as List<dynamic>? ?? const [];
      final out = <String, HistoryLatestByEventItem>{};
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final idRaw = m['eventId'] ?? m['event_id'];
        final id = idRaw == null ? '' : idRaw.toString().trim();
        if (id.isEmpty) continue;
        final atSec = _readUnixSec(m['occurredAt'] ?? m['occurred_at']);
        if (atSec == null || atSec < 1) continue;
        final remark =
            (readGatewayStr(m, 'remark', 'remark') ?? '').trim();
        final hidRaw = m['historyId'] ?? m['history_id'];
        final hid = hidRaw == null ? null : hidRaw.toString().trim();
        out[id] = HistoryLatestByEventItem(
          eventId: id,
          occurredAt: DateTime.fromMillisecondsSinceEpoch(
            atSec * 1000,
            isUtc: true,
          ),
          remark: remark,
          historyId: (hid == null || hid.isEmpty || hid == '0') ? null : hid,
        );
      }
      AppDebugLog.historyLatest(
        'latest-by-event ok deviceNoLen=${dn.length} count=${out.length}',
      );
      return out;
    } catch (e) {
      AppDebugLog.historyLatest('latest-by-event err=$e');
      return null;
    }
  }

  static int? _readUnixSec(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim());
  }
}
