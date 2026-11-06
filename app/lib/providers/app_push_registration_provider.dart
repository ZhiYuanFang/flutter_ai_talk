import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../config/app_notification_preference_store.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/session_provider.dart';
import '../push/live_activity_native.dart';
import '../push/live_activity_register_context_sync.dart';
import '../push/live_activity_registration_service.dart';
import '../ucg/push/ucg_push_registration_service.dart';

/// 全局推送注册服务（经 authorized ApiClient → `/app/api/push/*`）。
final appPushRegistrationServiceProvider =
    Provider<UcgPushRegistrationService>((ref) {
  final service = UcgPushRegistrationService(
    api: ref.watch(authorizedApiClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// 兼容旧引用名。
final ucgPushRegistrationServiceProvider = appPushRegistrationServiceProvider;

/// iOS Live Activity token → `/app/api/push/live-activity/register`。
final liveActivityRegistrationServiceProvider =
    Provider<LiveActivityRegistrationService>((ref) {
  final service = LiveActivityRegistrationService(
    api: ref.watch(authorizedApiClientProvider),
    pushRegistration: ref.watch(appPushRegistrationServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

Future<void>? _appPushRegisterInFlight;
const _kAppPushRegisterFailThreshold = 2;
var _appPushRegisterGaveUp = false;
var _appPushRegisterFailCount = 0;
var _appPushTokenRefreshDeferred = false;

void resetAppPushRegisterState() {
  _appPushRegisterGaveUp = false;
  _appPushRegisterFailCount = 0;
  _appPushTokenRefreshDeferred = false;
}

/// 登录后尽早注册；不依赖 UCG 会话 / chat WS。主壳须 [ref.watch] 以激活 listen。
final appPushBootstrapProvider = Provider<void>((ref) {
  final push = ref.watch(appPushRegistrationServiceProvider);

  unawaited(push.bindTokenRefreshListener(() async {
    if (_appPushRegisterInFlight != null) {
      _appPushTokenRefreshDeferred = true;
      return;
    }
    if (_appPushRegisterGaveUp) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    await syncAppPushRegistration(ref);
  }));

  final la = ref.watch(liveActivityRegistrationServiceProvider);

  ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
    if (!loggedIn) {
      resetAppPushRegisterState();
      // 登出：清原生 wxId 缓存，避免旧账号继续免鉴权上报
      unawaited(LiveActivityNative.clearRegisterContext());
      unawaited(push.unregister());
      unawaited(la.stop());
      return;
    }
    unawaited(syncAppPushRegistration(ref));
  });

  // access 轮换 / 初登：刷新原生 register 上下文（wxId 可能变）
  ref.listen<String?>(
    sessionProvider.select((s) => s.accessToken),
    (prev, next) {
      if (next == null || next.isEmpty) return;
      unawaited(
        syncLiveActivityRegisterContext(
          accessToken: next,
          pushRegistration: push,
        ),
      );
    },
  );

  if (ref.read(sessionProvider).isLoggedIn) {
    unawaited(syncAppPushRegistration(ref));
  }
});

/// 外部（如喂养页 bootstrap）也可主动触发。
Future<void> syncAppPushRegistration(dynamic ref) async {
  if (kIsWeb) return;
  if (_appPushRegisterInFlight != null) {
    await _appPushRegisterInFlight;
    return;
  }
  final run = _syncAppPushRegistrationOnce(ref);
  _appPushRegisterInFlight = run;
  try {
    await run;
  } finally {
    if (identical(_appPushRegisterInFlight, run)) {
      _appPushRegisterInFlight = null;
    }
    if (_appPushTokenRefreshDeferred) {
      _appPushTokenRefreshDeferred = false;
      if (ref.read(sessionProvider).isLoggedIn) {
        unawaited(syncAppPushRegistration(ref));
      }
    }
  }
}

Future<void> _syncAppPushRegistrationOnce(dynamic ref) async {
  final session = ref.read(sessionProvider);
  final push = ref.read(appPushRegistrationServiceProvider);
  final la = ref.read(liveActivityRegistrationServiceProvider)
      as LiveActivityRegistrationService;
  if (!session.isLoggedIn) {
    resetAppPushRegisterState();
    await LiveActivityNative.clearRegisterContext();
    await push.unregister();
    await la.stop();
    return;
  }
  // 唤醒窗原生 register 依赖缓存的 wxId/deviceKey/apiBase
  await syncLiveActivityRegisterContext(
    accessToken: session.accessToken,
    pushRegistration: push,
  );
  // 消息偏好仅约束设备 push；LA 监听与偏好解耦。
  final preferenceOn = await AppNotificationPreferenceStore.load();
  if (!preferenceOn) {
    AppDebugLog.ucgPush('register skip preference off (device push only)');
  } else if (_appPushRegisterGaveUp) {
    AppDebugLog.ucgPush('register skip gaveUp (device push only)');
  } else {
    try {
      await push.registerIfEligible(isLoggedIn: true);
      _appPushRegisterFailCount = 0;
    } catch (e) {
      _appPushRegisterFailCount++;
      AppDebugLog.ucgPush(
        'register fail count=$_appPushRegisterFailCount err=$e',
      );
      if (_appPushRegisterFailCount >= _kAppPushRegisterFailThreshold) {
        _appPushRegisterGaveUp = true;
        AppDebugLog.ucgPush('gaveUp after $_appPushRegisterFailCount failures');
      }
    }
  }
  // 已登录即可听 LA（Dart 补传）；主路径为原生免鉴权 register
  unawaited(la.startIfEligible(isLoggedIn: true));
}
