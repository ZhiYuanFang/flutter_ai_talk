import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueNotifier, defaultTargetPlatform, kIsWeb;

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../config/live_activity_registration_store.dart';
import '../ucg/push/ucg_push_registration_service.dart';
import 'live_activity_native.dart';
import 'live_activity_registration_status.dart';

/// iOS Live Activity token → `POST /app/api/push/live-activity/register`。
/// MUST NOT 走 `/app/api/push/register`。
class LiveActivityRegistrationService {
  LiveActivityRegistrationService({
    required ApiClient api,
    required UcgPushRegistrationService pushRegistration,
  })  : _api = api,
        _pushRegistration = pushRegistration {
    // 异步灌入持久化成功时间与系统态
    unawaited(_hydrateStatus());
  }

  final ApiClient _api;
  final UcgPushRegistrationService _pushRegistration;
  StreamSubscription<LiveActivityTokenEvent>? _sub;
  var _started = false;
  Completer<void>? _imminentPtsCompleter;
  Completer<void>? _timingPtsCompleter;

  /// UI 可监听的注册显态（无 token）。
  final ValueNotifier<LiveActivityRegistrationStatus> status =
      ValueNotifier(LiveActivityRegistrationStatus.initial());

  /// 已登录时启动原生监听并转发 HTTP（与消息通知偏好无关）。
  Future<void> startIfEligible({required bool isLoggedIn}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!isLoggedIn) {
      await stop();
      return;
    }
    if (_started) return;
    _started = true;
    // 先订阅再通知原生，避免 broadcast 丢首包
    await _sub?.cancel();
    _sub = LiveActivityNative.tokenStream.listen((ev) {
      unawaited(_register(ev));
    });
    await LiveActivityNative.startListening();
    await refreshSystemStatus();
    _patchStatus(listening: true);
    AppDebugLog.liveActivity('registration service started');
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    _imminentPtsCompleter = null;
    _timingPtsCompleter = null;
    _patchStatus(listening: false, retrying: false);
  }

  Future<void> dispose() async {
    await stop();
    status.dispose();
  }

  /// 刷新系统 Live Activities 允许态与 Push-to-Start 能力。
  Future<void> refreshSystemStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _patchStatus(
        pushToStartSupported: false,
        systemAuth: LiveActivitySystemAuth.unsupported,
      );
      return;
    }
    final info = await LiveActivityNative.getSystemStatus();
    final auth = !info.supported
        ? LiveActivitySystemAuth.unsupported
        : (info.areActivitiesEnabled
            ? LiveActivitySystemAuth.enabled
            : LiveActivitySystemAuth.disabled);
    _patchStatus(
      pushToStartSupported: info.pushToStartSupported,
      systemAuth: auth,
    );
  }

  /// 手动重试：强制重启监听并等待两类 push_to_start 上报。
  Future<void> forceRetryPushToStart({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _patchStatus(
        lastError: '当前平台不支持锁屏 Live Activity',
        clearLastError: false,
      );
      return;
    }
    _patchStatus(retrying: true, clearLastError: true);
    await refreshSystemStatus();
    final cur = status.value;
    if (!cur.pushToStartSupported) {
      _patchStatus(
        retrying: false,
        lastError: '系统版本过低，需要 iOS 17.2 及以上才能开通锁屏推送',
      );
      return;
    }
    if (cur.systemAuth == LiveActivitySystemAuth.disabled) {
      _patchStatus(
        retrying: false,
        lastError: '系统未允许实时活动 / Live Activities，请在系统设置中开启后再重试',
      );
      return;
    }

    final imminentDone = Completer<void>();
    final timingDone = Completer<void>();
    _imminentPtsCompleter = imminentDone;
    _timingPtsCompleter = timingDone;

    try {
      // 允许再次 start：清 Dart 门闩并重启原生观察
      await _sub?.cancel();
      _sub = null;
      _started = false;
      _sub = LiveActivityNative.tokenStream.listen((ev) {
        unawaited(_register(ev));
      });
      await LiveActivityNative.restartListening();
      _started = true;
      _patchStatus(listening: true);

      await Future.wait<void>([
        imminentDone.future,
        timingDone.future,
      ]).timeout(timeout);

      _patchStatus(retrying: false, clearLastError: true);
      AppDebugLog.liveActivity('forceRetry ok both push_to_start');
    } on TimeoutException {
      final after = status.value;
      final stillPartial = !after.imminentPushToStartOk ||
          !after.timingPushToStartOk;
      final msg = stillPartial
          ? '等待系统 Push-to-Start token 超时，未能完成上报'
          : '本次重试未收到新的系统 token；仍保留上次开通成功记录';
      _patchStatus(retrying: false, lastError: msg);
      AppDebugLog.liveActivity('forceRetry timeout stillPartial=$stillPartial');
    } catch (e) {
      _patchStatus(
        retrying: false,
        lastError: _userFacingError(e),
      );
      AppDebugLog.liveActivity('forceRetry err=$e');
    } finally {
      if (identical(_imminentPtsCompleter, imminentDone)) {
        _imminentPtsCompleter = null;
      }
      if (identical(_timingPtsCompleter, timingDone)) {
        _timingPtsCompleter = null;
      }
    }
  }

  Future<void> _hydrateStatus() async {
    final imminentAt = await LiveActivityRegistrationStore.loadImminentOkAt();
    final timingAt = await LiveActivityRegistrationStore.loadTimingOkAt();
    _patchStatus(
      imminentPushToStartOk: imminentAt != null,
      timingPushToStartOk: timingAt != null,
      imminentLastSuccessAt: imminentAt,
      timingLastSuccessAt: timingAt,
    );
    await refreshSystemStatus();
  }

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
      if (kind == 'push_to_start') {
        final now = DateTime.now();
        if (attr == 'imminent') {
          await LiveActivityRegistrationStore.saveImminentOkAt(now);
          _patchStatus(
            imminentPushToStartOk: true,
            imminentLastSuccessAt: now,
            clearLastError: true,
          );
          _completeIfPending(_imminentPtsCompleter);
        } else {
          await LiveActivityRegistrationStore.saveTimingOkAt(now);
          _patchStatus(
            timingPushToStartOk: true,
            timingLastSuccessAt: now,
            clearLastError: true,
          );
          _completeIfPending(_timingPtsCompleter);
        }
      }
    } catch (e) {
      final msg = _userFacingError(e);
      _patchStatus(lastError: msg);
      AppDebugLog.liveActivity('register err=$e');
    }
  }

  void _completeIfPending(Completer<void>? c) {
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  String _userFacingError(Object e) {
    if (e is ApiBusinessException) {
      return '上报失败（${e.code}）：${e.message}';
    }
    if (e is ApiHttpException) {
      final body = e.body.trim();
      final short =
          body.length > 120 ? '${body.substring(0, 120)}…' : body;
      return '网络/HTTP 失败（${e.statusCode}）${short.isEmpty ? '' : '：$short'}';
    }
    final raw = e.toString();
    // 避免异常串里夹带超长 hex token
    if (raw.length > 180) {
      return '注册失败：${raw.substring(0, 180)}…';
    }
    return '注册失败：$raw';
  }

  void _patchStatus({
    bool? listening,
    bool? pushToStartSupported,
    LiveActivitySystemAuth? systemAuth,
    bool? imminentPushToStartOk,
    bool? timingPushToStartOk,
    DateTime? imminentLastSuccessAt,
    DateTime? timingLastSuccessAt,
    String? lastError,
    bool clearLastError = false,
    bool? retrying,
  }) {
    status.value = status.value.copyWith(
      listening: listening,
      pushToStartSupported: pushToStartSupported,
      systemAuth: systemAuth,
      imminentPushToStartOk: imminentPushToStartOk,
      timingPushToStartOk: timingPushToStartOk,
      imminentLastSuccessAt: imminentLastSuccessAt,
      timingLastSuccessAt: timingLastSuccessAt,
      lastError: lastError,
      clearLastError: clearLastError,
      retrying: retrying,
    );
  }
}
