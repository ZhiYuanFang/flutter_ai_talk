import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../api/api_client.dart';
import '../api/app_debug_log.dart';
import '../ucg/push/ucg_push_registration_service.dart';
import 'live_activity_native.dart';

/// iOS Live Activity token → `POST /app/api/push/live-activity/register`。
/// MUST NOT 走 `/app/api/push/register`。
class LiveActivityRegistrationService {
  LiveActivityRegistrationService({
    required ApiClient api,
    required UcgPushRegistrationService pushRegistration,
  })  : _api = api,
        _pushRegistration = pushRegistration;

  final ApiClient _api;
  final UcgPushRegistrationService _pushRegistration;
  StreamSubscription<LiveActivityTokenEvent>? _sub;
  var _started = false;

  /// 已登录时启动原生监听并转发 HTTP。
  Future<void> startIfEligible({required bool isLoggedIn}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!isLoggedIn) {
      await stop();
      return;
    }
    if (_started) return;
    _started = true;
    await LiveActivityNative.startListening();
    await _sub?.cancel();
    _sub = LiveActivityNative.tokenStream.listen((ev) {
      unawaited(_register(ev));
    });
    AppDebugLog.liveActivity('registration service started');
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  Future<void> dispose() => stop();

  Future<void> _register(LiveActivityTokenEvent ev) async {
    final kind = ev.tokenKind.trim().toLowerCase();
    final attr = ev.attributesKind.trim().toLowerCase();
    if (kind != 'push_to_start' && kind != 'activity') {
      AppDebugLog.liveActivity('skip bad tokenKind=$kind');
      return;
    }
    if (attr != 'imminent' && attr != 'timing') {
      AppDebugLog.liveActivity('skip bad attributesKind=$attr');
      return;
    }
    if (kind == 'activity' &&
        (ev.activityId == null || ev.activityId!.trim().isEmpty)) {
      AppDebugLog.liveActivity('skip activity without activityId');
      return;
    }
    try {
      final deviceKey = await _pushRegistration.deviceKey();
      final body = <String, dynamic>{
        'deviceKey': deviceKey,
        'tokenKind': kind,
        'attributesKind': attr,
        'token': ev.token,
      };
      if (kind == 'activity') {
        body['activityId'] = ev.activityId!.trim();
      }
      // 专用 LA 路径，禁止复用 device push register
      await _api.postJsonEnvelope(
        '/app/api/push/live-activity/register',
        body,
      );
      AppDebugLog.liveActivity(
        'register ok kind=$kind attr=$attr activityIdLen=${ev.activityId?.length ?? 0}',
      );
    } catch (e) {
      AppDebugLog.liveActivity('register err=$e');
    }
  }
}
