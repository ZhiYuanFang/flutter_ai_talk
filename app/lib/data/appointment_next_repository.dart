import '../api/api_client.dart';
import '../api/app_debug_log.dart';

/// 预约下次约定值：unix 秒 nextAt + 备注（与 Go twin 对齐）。
class AppointmentNextValue {
  const AppointmentNextValue({
    required this.nextAtSec,
    this.remark = '',
  });

  /// 下次触发 unix 秒；0=无约定。
  final int nextAtSec;

  /// 预约备注；空串合法；客户端不 Trim。
  final String remark;

  static const empty = AppointmentNextValue(nextAtSec: 0, remark: '');

  AppointmentNextValue copyWith({int? nextAtSec, String? remark}) {
    return AppointmentNextValue(
      nextAtSec: nextAtSec ?? this.nextAtSec,
      remark: remark ?? this.remark,
    );
  }
}

/// 备注最大长度（与 Go VARCHAR(512) / rune 上限对齐）。
const kAppointmentRemarkMaxLen = 512;

/// 截断到 max runes（不 Trim）。
String clampAppointmentRemark(String raw) {
  if (raw.runes.length <= kAppointmentRemarkMaxLen) return raw;
  return String.fromCharCodes(raw.runes.take(kAppointmentRemarkMaxLen));
}

/// 预约下次约定：`GET/PUT /device/app/api/appointment/next`。
class AppointmentNextRepository {
  AppointmentNextRepository(this._api);

  final ApiClient _api;

  /// 读取约定；无行返回 nextAt=0、remark=''。
  Future<AppointmentNextValue> getNext({
    required String deviceNo,
    required String eventId,
  }) async {
    final dn = deviceNo.trim();
    final eid = int.tryParse(eventId.trim());
    if (dn.isEmpty || eid == null || eid < 1) {
      return AppointmentNextValue.empty;
    }
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
    // 备注原样保留，不 Trim
    final remark = data?['remark']?.toString() ?? '';
    AppDebugLog.appointmentNext(
      'GET ok eventId=$eid nextAt=$nextAt remarkLen=${remark.runes.length}',
    );
    return AppointmentNextValue(nextAtSec: nextAt, remark: remark);
  }

  /// 写入约定；`nextAt=0` 清空（服务端清备注）；MUST 始终传 remark。
  Future<void> putNext({
    required String deviceNo,
    required String eventId,
    required int nextAt,
    required String remark,
  }) async {
    final dn = deviceNo.trim();
    final eid = int.tryParse(eventId.trim());
    if (dn.isEmpty || eid == null || eid < 1) return;
    final sec = nextAt < 0 ? 0 : nextAt;
    final rm = clampAppointmentRemark(remark);
    await _api.putJsonEnvelope(
      '/device/app/api/appointment/next',
      {
        'deviceNo': dn,
        'eventId': eid,
        'nextAt': sec,
        'remark': rm,
      },
    );
    AppDebugLog.appointmentNext(
      'PUT ok eventId=$eid nextAt=$sec remarkLen=${rm.runes.length}',
    );
  }
}
