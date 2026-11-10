import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../api/app_debug_log.dart';
import '../providers/app_push_registration_provider.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/session_provider.dart';
import 'live_activity_native.dart';

/// 登录态下本机无统一 LA 时，鉴权 clear 服务端该机 `token_kind=activity`。
///
/// 副作用 HTTP：single-flight、成功短窗跳过、失败可观测；非 iOS 直接跳过。
Future<void>? _clearInFlight;
DateTime? _lastClearOkAt;
String? _lastClearOkDeviceKey;

/// 连续 resumed 合并窗口。
const _coalesceWindow = Duration(seconds: 3);

/// 同 deviceKey 成功后的幂等跳过窗口。
const _successSkipWindow = Duration(seconds: 8);

DateTime? _coalesceUntil;
Timer? _coalesceTimer;
Completer<void>? _coalesceCompleter;

bool get _isIosLiveActivityPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// 冷启动就绪 / resumed / 登录成功后调用：无本机 LA 则 clear。
Future<void> maybeClearServerActivityTokenIfNoLocalLiveActivity(
  dynamic ref,
) async {
  if (!_isIosLiveActivityPlatform) return;

  // 短窗合并连续 lifecycle 触发，共享一次实际检查。
  final now = DateTime.now();
  final until = _coalesceUntil;
  if (until != null && now.isBefore(until) && _coalesceCompleter != null) {
    return _coalesceCompleter!.future;
  }

  _coalesceUntil = now.add(_coalesceWindow);
  final completer = Completer<void>();
  _coalesceCompleter = completer;
  _coalesceTimer?.cancel();
  _coalesceTimer = Timer(const Duration(milliseconds: 200), () async {
    try {
      await _runClearCheck(ref);
    } catch (e) {
      // 不得静默；unawaited 调用方不依赖异常冒泡。
      AppDebugLog.liveActivity('activityClear coalesce err=$e');
    } finally {
      if (!completer.isCompleted) completer.complete();
      if (identical(_coalesceCompleter, completer)) {
        _coalesceCompleter = null;
      }
    }
  });
  return completer.future;
}

Future<void> _runClearCheck(dynamic ref) async {
  final existing = _clearInFlight;
  if (existing != null) {
    await existing;
    return;
  }

  final run = _runClearCheckOnce(ref);
  _clearInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_clearInFlight, run)) {
      _clearInFlight = null;
    }
  }
}

Future<void> _runClearCheckOnce(dynamic ref) async {
  final session = ref.read(sessionProvider);
  if (!session.isLoggedIn) {
    AppDebugLog.liveActivity('activityClear skip not_logged_in');
    return;
  }

  final hasLocal = await LiveActivityNative.hasActiveUnifiedLiveActivity();
  if (hasLocal == null) {
    AppDebugLog.liveActivity('activityClear skip query_failed');
    return;
  }
  if (hasLocal) {
    AppDebugLog.liveActivity('activityClear skip has_local_la');
    return;
  }

  final push = ref.read(appPushRegistrationServiceProvider);
  final deviceKey = (await push.deviceKey()).trim();
  if (deviceKey.isEmpty) {
    AppDebugLog.liveActivity('activityClear skip empty_deviceKey');
    return;
  }

  final lastAt = _lastClearOkAt;
  final lastKey = _lastClearOkDeviceKey;
  if (lastAt != null &&
      lastKey == deviceKey &&
      DateTime.now().difference(lastAt) < _successSkipWindow) {
    AppDebugLog.liveActivity('activityClear skip recent_ok');
    return;
  }

  try {
    final api = ref.read(authorizedApiClientProvider);
    await api.postJsonEnvelope(
      '/app/api/push/live-activity/activity/clear',
      {'deviceKey': deviceKey},
    );
    _lastClearOkAt = DateTime.now();
    _lastClearOkDeviceKey = deviceKey;
    AppDebugLog.liveActivity('activityClear ok deviceKeyLen=${deviceKey.length}');
  } catch (e) {
    AppDebugLog.liveActivity('activityClear err=$e');
  }
}
