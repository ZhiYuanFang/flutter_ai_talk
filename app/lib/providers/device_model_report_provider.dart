import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/device_model_repository.dart';
import '../data/device_model_resolve.dart';
import '../session/token_expiry.dart';
import 'authorized_api_client_provider.dart';
import 'session_provider.dart';

/// 设备型号上报仓库（须已登录 Bearer）。
final deviceModelRepositoryProvider = Provider<DeviceModelRepository>((ref) {
  return DeviceModelRepository(ref.watch(authorizedApiClientProvider));
});

const _kPrefsWx = 'device_model_report_wx';
const _kPrefsValue = 'device_model_report_value';
const _kPrefsAtMs = 'device_model_report_at_ms';

/// 同账号同值成功后 24h 内跳过。
const _throttleWindow = Duration(hours: 24);

/// 失败短熔断。
const _failureCooldown = Duration(minutes: 5);

Future<void>? _inFlight;
DateTime? _cooldownUntil;

/// 登录后 / resume：解析并上报设备型号（fire-and-forget 入口请 `unawaited`）。
///
/// - 未登录 / Web / 空型号：跳过
/// - 按 JWT wxId 节流；single-flight；失败熔断
/// - **不得**在 provider 创建时自动调用
Future<void> syncDeviceModelReport(dynamic ref) async {
  final existing = _inFlight;
  if (existing != null) {
    await existing;
    return;
  }
  final run = _syncDeviceModelReportOnce(ref);
  _inFlight = run;
  try {
    await run;
  } finally {
    if (identical(_inFlight, run)) {
      _inFlight = null;
    }
  }
}

Future<void> _syncDeviceModelReportOnce(dynamic ref) async {
  // 熔断窗内跳过
  final until = _cooldownUntil;
  if (until != null && DateTime.now().isBefore(until)) {
    AppDebugLog.deviceModel('skip cooldown');
    return;
  }

  if (!ref.read(sessionProvider).isLoggedIn) {
    AppDebugLog.deviceModel('skip not logged in');
    return;
  }

  final token = ref.read(sessionProvider).accessToken;
  final wxId = readJwtWxId(token) ?? '_anon';

  final model = await resolveDeviceModelString();
  if (model == null || model.isEmpty) {
    AppDebugLog.deviceModel('skip unresolved platform/model');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final lastWx = prefs.getString(_kPrefsWx) ?? '';
  final lastValue = prefs.getString(_kPrefsValue) ?? '';
  final lastAtMs = prefs.getInt(_kPrefsAtMs) ?? 0;
  final lastAt = lastAtMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastAtMs)
      : null;
  if (lastWx == wxId &&
      lastValue == model &&
      lastAt != null &&
      DateTime.now().difference(lastAt) < _throttleWindow) {
    AppDebugLog.deviceModel('skip throttle same wx+model');
    return;
  }

  try {
    final DeviceModelRepository repo = ref.read(deviceModelRepositoryProvider);
    await repo.report(model);
    await prefs.setString(_kPrefsWx, wxId);
    await prefs.setString(_kPrefsValue, model);
    await prefs.setInt(_kPrefsAtMs, DateTime.now().millisecondsSinceEpoch);
    _cooldownUntil = null;
  } catch (_) {
    _cooldownUntil = DateTime.now().add(_failureCooldown);
    // 已在 repository 打日志；此处不 Toast
  }
}
