import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueNotifier, defaultTargetPlatform, kIsWeb;

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../config/live_activity_registration_store.dart';
import '../data/event_catalog_store.dart';
import '../ucg/push/ucg_push_registration_service.dart';
import 'live_activity_event_visuals.dart';
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

  /// 成功 register 身份缓存（副作用 HTTP 去重；登出清）。
  final Set<String> _registeredIdentities = <String>{};

  /// 本轮手动重试：是否见过 PTS / 是否已记 HTTP 失败（防超时覆盖）。
  var _attemptImminentSeen = false;
  var _attemptTimingSeen = false;
  var _attemptHttpFailed = false;
  String? _attemptHttpError;

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
    // 预热 App Group 视觉索引，供锁屏 Extension 按 eventId 取图/色
    unawaited(_syncEventVisuals());
    AppDebugLog.liveActivity('registration service started');
  }

  Future<void> _syncEventVisuals() async {
    try {
      final catalog = await EventCatalogStore.loadFromDisk();
      await syncLiveActivityEventVisuals(catalog);
    } catch (e) {
      AppDebugLog.liveActivity('visuals sync err=$e');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    _imminentPtsCompleter = null;
    _timingPtsCompleter = null;
    // 停投递但保留原生观察；token 入 inbox 待下次登录 flush
    await LiveActivityNative.pauseDartListening();
    _registeredIdentities.clear();
    _patchStatus(listening: false, retrying: false);
  }

  Future<void> dispose() async {
    await stop();
    status.dispose();
  }

  /// 刷新系统 Live Activities 允许态、Push-to-Start 能力与原生 deliver 计数。
  Future<void> refreshSystemStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _patchStatus(
        pushToStartSupported: false,
        systemAuth: LiveActivitySystemAuth.unsupported,
        iosVersionLabel: '',
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
      pushToStartDeliverCount: info.pushToStartDeliverCount,
      iosVersionLabel: info.iosVersion,
    );
  }

  /// 手动重试：强制重启监听并等待两类 push_to_start 上报。
  Future<void> forceRetryPushToStart({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _patchStatus(
        lastError: '当前平台不支持锁屏 Live Activity',
        errorCategory: LiveActivityErrorCategory.unknown,
      );
      return;
    }
    _attemptImminentSeen = false;
    _attemptTimingSeen = false;
    _attemptHttpFailed = false;
    _attemptHttpError = null;
    _patchStatus(
      retrying: true,
      clearLastError: true,
      clearErrorCategory: true,
    );
    await refreshSystemStatus();
    final cur = status.value;
    if (!cur.pushToStartSupported) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.osUnsupported,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.osUnsupported,
        ),
      );
      return;
    }
    if (cur.systemAuth == LiveActivitySystemAuth.disabled) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.systemDisallowed,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.systemDisallowed,
        ),
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
      await refreshSystemStatus();
      unawaited(_syncEventVisuals());

      await Future.wait<void>([
        imminentDone.future,
        timingDone.future,
      ]).timeout(timeout);

      _patchStatus(
        retrying: false,
        clearLastError: true,
        clearErrorCategory: true,
      );
      AppDebugLog.liveActivity('forceRetry ok both push_to_start');
    } on TimeoutException {
      await refreshSystemStatus();
      _applyTimeoutDiagnosis();
      AppDebugLog.liveActivity(
        'forceRetry timeout cat=${status.value.errorCategoryCode} '
        'attImm=$_attemptImminentSeen attTim=$_attemptTimingSeen '
        'httpFail=$_attemptHttpFailed',
      );
    } catch (e) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.unknown,
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

  /// 超时后按本轮证据分类，禁止用「无 token」盖住 HTTP 错。
  void _applyTimeoutDiagnosis() {
    final after = status.value;
    if (_attemptHttpFailed) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.registerHttpFailed,
        lastError: _attemptHttpError ??
            liveActivityErrorCategoryMessage(
              LiveActivityErrorCategory.registerHttpFailed,
            ),
      );
      return;
    }
    final bothOk =
        after.imminentPushToStartOk && after.timingPushToStartOk;
    if (bothOk) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.timeoutKeptPriorSuccess,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.timeoutKeptPriorSuccess,
        ),
      );
      return;
    }
    final anySeen = _attemptImminentSeen || _attemptTimingSeen;
    final deliver = after.pushToStartDeliverCount;
    // 原生已 invoke 但 Dart 未见事件（通道异常）；成功开通后不应再出现 deliver>0 && seen=0
    if (!anySeen && deliver > 0) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.nativeDeliverDartMiss,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.nativeDeliverDartMiss,
        ),
      );
      return;
    }
    if (!anySeen && deliver <= 0) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.noSystemToken,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.noSystemToken,
        ),
      );
      return;
    }
    // 本轮至少见过一类事件，但两类未齐成功
    _patchStatus(
      retrying: false,
      errorCategory: LiveActivityErrorCategory.partialAttributes,
      lastError: liveActivityErrorCategoryMessage(
        LiveActivityErrorCategory.partialAttributes,
      ),
    );
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
    if (kind == 'push_to_start') {
      // 先标记「已见事件」，与 HTTP 成败分离
      if (attr == 'imminent') {
        _attemptImminentSeen = true;
        _patchStatus(imminentPtsEventSeen: true);
      } else {
        _attemptTimingSeen = true;
        _patchStatus(timingPtsEventSeen: true);
      }
    }
    try {
      final deviceKey = await _pushRegistration.deviceKey();
      final activityId =
          kind == 'activity' ? ev.activityId!.trim() : '';
      // 成功身份：不变则跳过重复 POST（early observe + 补扫易连打）
      final identity =
          '$deviceKey|$kind|$attr|$activityId|${ev.token}';
      if (_registeredIdentities.contains(identity)) {
        AppDebugLog.liveActivity(
          'register skip cached kind=$kind attr=$attr '
          'activityIdLen=${activityId.length}',
        );
        if (kind == 'push_to_start') {
          _completeIfPending(
            attr == 'imminent' ? _imminentPtsCompleter : _timingPtsCompleter,
          );
        }
        return;
      }
      final body = <String, dynamic>{
        'deviceKey': deviceKey,
        'tokenKind': kind,
        'attributesKind': attr,
        'token': ev.token,
      };
      if (kind == 'activity') {
        body['activityId'] = activityId;
      }
      // 专用 LA 路径，禁止复用 device push register
      await _api.postJsonEnvelope(
        '/app/api/push/live-activity/register',
        body,
      );
      _registeredIdentities.add(identity);
      AppDebugLog.liveActivity(
        'register ok kind=$kind attr=$attr activityIdLen=${activityId.length}',
      );
      if (kind == 'push_to_start') {
        final now = DateTime.now();
        if (attr == 'imminent') {
          await LiveActivityRegistrationStore.saveImminentOkAt(now);
          _patchStatus(
            imminentPushToStartOk: true,
            imminentLastSuccessAt: now,
            clearLastError: true,
            clearErrorCategory: true,
          );
          _completeIfPending(_imminentPtsCompleter);
        } else {
          await LiveActivityRegistrationStore.saveTimingOkAt(now);
          _patchStatus(
            timingPushToStartOk: true,
            timingLastSuccessAt: now,
            clearLastError: true,
            clearErrorCategory: true,
          );
          _completeIfPending(_timingPtsCompleter);
        }
      }
    } catch (e) {
      final msg = _userFacingError(e);
      _attemptHttpFailed = true;
      _attemptHttpError = msg;
      _patchStatus(
        lastError: msg,
        errorCategory: LiveActivityErrorCategory.registerHttpFailed,
      );
      // 勿把完整异常串（可能含 token）打满；截断已在 _userFacingError
      AppDebugLog.liveActivity('register err=$msg');
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
    bool? imminentPtsEventSeen,
    bool? timingPtsEventSeen,
    DateTime? imminentLastSuccessAt,
    DateTime? timingLastSuccessAt,
    int? pushToStartDeliverCount,
    String? iosVersionLabel,
    String? lastError,
    bool clearLastError = false,
    LiveActivityErrorCategory? errorCategory,
    bool clearErrorCategory = false,
    bool? retrying,
  }) {
    status.value = status.value.copyWith(
      listening: listening,
      pushToStartSupported: pushToStartSupported,
      systemAuth: systemAuth,
      imminentPushToStartOk: imminentPushToStartOk,
      timingPushToStartOk: timingPushToStartOk,
      imminentPtsEventSeen: imminentPtsEventSeen,
      timingPtsEventSeen: timingPtsEventSeen,
      imminentLastSuccessAt: imminentLastSuccessAt,
      timingLastSuccessAt: timingLastSuccessAt,
      pushToStartDeliverCount: pushToStartDeliverCount,
      iosVersionLabel: iosVersionLabel,
      lastError: lastError,
      clearLastError: clearLastError,
      errorCategory: errorCategory,
      clearErrorCategory: clearErrorCategory,
      retrying: retrying,
    );
  }
}
