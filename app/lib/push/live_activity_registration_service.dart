import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueNotifier, defaultTargetPlatform, kIsWeb;

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../config/live_activity_registration_store.dart';
import '../data/event_catalog_store.dart';
import '../session/token_expiry.dart';
import '../ucg/push/ucg_push_registration_service.dart';
import 'live_activity_event_visuals.dart';
import 'live_activity_native.dart';
import 'live_activity_registration_status.dart';

/// iOS Live Activity token → `POST /app/api/push/live-activity/register`（统一单轨）。
/// Dart 为可选补传；唤醒窗主路径在原生免鉴权 POST。MUST NOT 走 `/app/api/push/register`。
class LiveActivityRegistrationService {
  LiveActivityRegistrationService({
    required ApiClient api,
    required UcgPushRegistrationService pushRegistration,
  })  : _api = api,
        _pushRegistration = pushRegistration {
    unawaited(_hydrateStatus());
  }

  final ApiClient _api;
  final UcgPushRegistrationService _pushRegistration;
  StreamSubscription<LiveActivityTokenEvent>? _sub;
  var _started = false;
  Completer<void>? _ptsCompleter;

  /// 成功 register 身份缓存（副作用 HTTP 去重；登出清）。
  final Set<String> _registeredIdentities = <String>{};

  /// 本轮手动重试证据。
  var _attemptPtsSeen = false;
  var _attemptHttpFailed = false;
  String? _attemptHttpError;

  final ValueNotifier<LiveActivityRegistrationStatus> status =
      ValueNotifier(LiveActivityRegistrationStatus.initial());

  /// 已登录时启动原生监听并做 Dart 侧补传 HTTP。
  Future<void> startIfEligible({required bool isLoggedIn}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!isLoggedIn) {
      await stop();
      return;
    }
    if (_started) return;
    _started = true;
    await _sub?.cancel();
    _sub = LiveActivityNative.tokenStream.listen((ev) {
      unawaited(_register(ev));
    });
    await LiveActivityNative.startListening();
    await refreshSystemStatus();
    _patchStatus(listening: true);
    unawaited(_syncEventVisuals());
    AppDebugLog.liveActivity('registration service started (dart supplemental)');
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
    _ptsCompleter = null;
    await LiveActivityNative.pauseDartListening();
    _registeredIdentities.clear();
    _patchStatus(listening: false, retrying: false);
  }

  Future<void> dispose() async {
    await stop();
    status.dispose();
  }

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

  /// 手动重试：强制重启监听并等待统一轨 push_to_start 上报。
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
    _attemptPtsSeen = false;
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

    final ptsDone = Completer<void>();
    _ptsCompleter = ptsDone;

    try {
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

      await ptsDone.future.timeout(timeout);

      _patchStatus(
        retrying: false,
        clearLastError: true,
        clearErrorCategory: true,
      );
      AppDebugLog.liveActivity('forceRetry ok push_to_start');
    } on TimeoutException {
      await refreshSystemStatus();
      _applyTimeoutDiagnosis();
      AppDebugLog.liveActivity(
        'forceRetry timeout cat=${status.value.errorCategoryCode} '
        'attSeen=$_attemptPtsSeen httpFail=$_attemptHttpFailed',
      );
    } catch (e) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.unknown,
        lastError: _userFacingError(e),
      );
      AppDebugLog.liveActivity('forceRetry err=$e');
    } finally {
      if (identical(_ptsCompleter, ptsDone)) {
        _ptsCompleter = null;
      }
    }
  }

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
    if (after.pushToStartOk) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.timeoutKeptPriorSuccess,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.timeoutKeptPriorSuccess,
        ),
      );
      return;
    }
    final deliver = after.pushToStartDeliverCount;
    if (!_attemptPtsSeen && deliver > 0) {
      _patchStatus(
        retrying: false,
        errorCategory: LiveActivityErrorCategory.nativeDeliverDartMiss,
        lastError: liveActivityErrorCategoryMessage(
          LiveActivityErrorCategory.nativeDeliverDartMiss,
        ),
      );
      return;
    }
    _patchStatus(
      retrying: false,
      errorCategory: LiveActivityErrorCategory.noSystemToken,
      lastError: liveActivityErrorCategoryMessage(
        LiveActivityErrorCategory.noSystemToken,
      ),
    );
  }

  Future<void> _hydrateStatus() async {
    final at = await LiveActivityRegistrationStore.loadPushToStartOkAt();
    _patchStatus(
      pushToStartOk: at != null,
      lastSuccessAt: at,
    );
    await refreshSystemStatus();
  }

  Future<void> _register(LiveActivityTokenEvent ev) async {
    final kind = ev.tokenKind.trim().toLowerCase();
    if (kind != 'push_to_start' && kind != 'activity') {
      AppDebugLog.liveActivity('skip bad tokenKind=$kind');
      return;
    }
    if (kind == 'push_to_start') {
      _attemptPtsSeen = true;
      _patchStatus(ptsEventSeen: true);
    }
    try {
      final wxRaw = readJwtWxId(_api.accessTokenProvider());
      final wxId = int.tryParse(wxRaw?.trim() ?? '') ?? 0;
      if (wxId <= 0) {
        AppDebugLog.liveActivity('skip register no wxId');
        return;
      }
      final deviceKey = await _pushRegistration.deviceKey();
      // 成功身份：无 attributesKind / activityId
      final identity = '$wxId|$deviceKey|$kind|${ev.token}';
      if (_registeredIdentities.contains(identity)) {
        AppDebugLog.liveActivity('register skip cached kind=$kind');
        if (kind == 'push_to_start') {
          _completeIfPending(_ptsCompleter);
        }
        return;
      }
      final body = <String, dynamic>{
        'wxId': wxId,
        'deviceKey': deviceKey,
        'tokenKind': kind,
        'token': ev.token,
      };
      await _api.postJsonEnvelope(
        '/app/api/push/live-activity/register',
        body,
      );
      _registeredIdentities.add(identity);
      AppDebugLog.liveActivity('register ok kind=$kind');
      if (kind == 'push_to_start') {
        final now = DateTime.now();
        await LiveActivityRegistrationStore.savePushToStartOkAt(now);
        _patchStatus(
          pushToStartOk: true,
          lastSuccessAt: now,
          clearLastError: true,
          clearErrorCategory: true,
        );
        _completeIfPending(_ptsCompleter);
      }
    } catch (e) {
      final msg = _userFacingError(e);
      _attemptHttpFailed = true;
      _attemptHttpError = msg;
      _patchStatus(
        lastError: msg,
        errorCategory: LiveActivityErrorCategory.registerHttpFailed,
      );
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
    if (raw.length > 180) {
      return '注册失败：${raw.substring(0, 180)}…';
    }
    return '注册失败：$raw';
  }

  void _patchStatus({
    bool? listening,
    bool? pushToStartSupported,
    LiveActivitySystemAuth? systemAuth,
    bool? pushToStartOk,
    bool? ptsEventSeen,
    DateTime? lastSuccessAt,
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
      pushToStartOk: pushToStartOk,
      ptsEventSeen: ptsEventSeen,
      lastSuccessAt: lastSuccessAt,
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
