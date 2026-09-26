import '../api/api_client.dart';
import '../api/app_debug_log.dart';

/// 预约下次约定：`GET/PUT /device/app/api/appointment/next`。
class AppointmentNextRepository {
  AppointmentNextRepository(this._api);

  final ApiClient _api;

  /// 读取约定；无行返回 `0`。
  Future<int> getNextAt({
    required String deviceNo,
    required String eventId,
  }) async {
    final dn = deviceNo.trim();
    final eid = int.tryParse(eventId.trim());
    if (dn.isEmpty || eid == null || eid < 1) return 0;
    final data = await _api.getEnvelope(
      '/device/app/api/appointment/next',
      query: {
        'deviceNo': dn,
        'eventId': '$eid',
      },
    );
    final raw = data?['nextAt'];
    final sec = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    final nextAt = sec < 0 ? 0 : sec;
    AppDebugLog.appointmentNext(
      'GET ok eventId=$eid nextAt=$nextAt',
    );
    return nextAt;
  }

  /// 写入约定；`nextAt=0` 清空。
  Future<void> putNextAt({
    required String deviceNo,
    required String eventId,
    required int nextAt,
  }) async {
    final dn = deviceNo.trim();
    final eid = int.tryParse(eventId.trim());
    if (dn.isEmpty || eid == null || eid < 1) return;
    final sec = nextAt < 0 ? 0 : nextAt;
    await _api.putJsonEnvelope(
      '/device/app/api/appointment/next',
      {
        'deviceNo': dn,
        'eventId': eid,
        'nextAt': sec,
      },
    );
    AppDebugLog.appointmentNext(
      'PUT ok eventId=$eid nextAt=$sec',
    );
  }
}
