import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../data/care_alert_repository.dart';
import '../data/feature_unlock_models.dart';
import '../data/feature_unlock_repository.dart';
import '../data/prediction_care_alert.dart';
import '../util/thinking_stage_delta.dart';
import 'authorized_api_client_provider.dart';
import 'cash_vip_provider.dart';
import 'device_no_notifier.dart';
import 'feature_unlock_provider.dart';
import 'forecast_toggle_provider.dart';
import 'session_provider.dart';

/// Care-alert 日列表 API 仓储。
final careAlertRepositoryProvider = Provider<CareAlertRepository>((ref) {
  return CareAlertRepository(ref.watch(authorizedApiClientProvider));
});

/// cash 资格 / 功能仓储（值得留意 eligibility 走 cash）。
final careAlertFeatureUnlockRepositoryProvider =
    Provider<FeatureUnlockRepository>((ref) {
  return FeatureUnlockRepository(ref.watch(authorizedApiClientProvider));
});

/// cash 值得留意喂养资格态。
class CareAlertEligibilityState {
  const CareAlertEligibilityState({
    this.data,
    this.loading = false,
    this.ready = false,
    this.failed = false,
    this.deviceNo = '',
  });

  final UcgEligibility? data;
  final bool loading;
  final bool ready;
  final bool failed;
  final String deviceNo;

  bool get isQualified => data?.qualified == true;

  CareAlertEligibilityState copyWith({
    UcgEligibility? data,
    bool? loading,
    bool? ready,
    bool? failed,
    String? deviceNo,
  }) {
    return CareAlertEligibilityState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      failed: failed ?? this.failed,
      deviceNo: deviceNo ?? this.deviceNo,
    );
  }
}

class CareAlertEligibilityNotifier
    extends StateNotifier<CareAlertEligibilityState> {
  CareAlertEligibilityNotifier(this._ref)
      : super(const CareAlertEligibilityState());

  final Ref _ref;
  Future<void>? _inFlight;

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      state = const CareAlertEligibilityState();
      return Future.value();
    }
    return _inFlight ??= _ensureImpl(force: force).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _ensureImpl({required bool force}) async {
    var dn = _deviceNoOrNull();
    if (dn == null) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      dn = _deviceNoOrNull();
    }
    if (dn == null) {
      state = const CareAlertEligibilityState();
      return;
    }
    if (!force &&
        state.ready &&
        !state.failed &&
        state.deviceNo == dn &&
        !state.loading) {
      return;
    }
    state = state.copyWith(loading: true, failed: false, deviceNo: dn);
    try {
      final e = await _ref
          .read(careAlertFeatureUnlockRepositoryProvider)
          .fetchCareAlertEligibility();
      state = CareAlertEligibilityState(
        data: e,
        loading: false,
        ready: true,
        failed: false,
        deviceNo: dn,
      );
    } catch (err) {
      AppDebugLog.careAlert('eligibility ensure err=$err');
      state = CareAlertEligibilityState(
        data: null,
        loading: false,
        ready: false,
        failed: true,
        deviceNo: dn,
      );
    }
  }

  void clear() {
    _inFlight = null;
    state = const CareAlertEligibilityState();
  }
}

final careAlertEligibilityStateProvider = StateNotifierProvider<
    CareAlertEligibilityNotifier, CareAlertEligibilityState>((ref) {
  final n = CareAlertEligibilityNotifier(ref);
  ref.listen(sessionProvider, (prev, next) {
    if (!next.isLoggedIn) n.clear();
  });
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    final dn = next.asData?.value?.trim();
    if (dn == null || dn.isEmpty) return;
    final prevDn = prev?.asData?.value?.trim();
    if (prevDn == dn) return;
    n.clear();
  });
  return n;
});

/// 日拉取状态：原始服务端列表（未做推演过滤）+ 日用量 + 思考流缓冲。
class PredictionCareAlertState {
  const PredictionCareAlertState({
    this.items = const [],
    this.loading = false,
    this.ready = false,
    this.failed = false,
    this.dayKey = '',
    this.deviceNo = '',
    this.usedToday = 0,
    this.dailyLimit = 5,
    this.thinking = '',
  });

  final List<CareAlertEventItem> items;
  final bool loading;
  final bool ready;
  final bool failed;
  final String dayKey;
  final String deviceNo;
  final int usedToday;
  final int dailyLimit;
  final String thinking;

  /// 与成长轨迹同款用量文案。
  String get usageCopy => '今日已用 $usedToday/$dailyLimit 次';

  PredictionCareAlertState copyWith({
    List<CareAlertEventItem>? items,
    bool? loading,
    bool? ready,
    bool? failed,
    String? dayKey,
    String? deviceNo,
    int? usedToday,
    int? dailyLimit,
    String? thinking,
  }) {
    return PredictionCareAlertState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      failed: failed ?? this.failed,
      dayKey: dayKey ?? this.dayKey,
      deviceNo: deviceNo ?? this.deviceNo,
      usedToday: usedToday ?? this.usedToday,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      thinking: thinking ?? this.thinking,
    );
  }
}

/// 日列表仅允许喂养工作台手动刷新；single-flight。
class PredictionCareAlertNotifier
    extends StateNotifier<PredictionCareAlertState> {
  PredictionCareAlertNotifier(this._ref)
      : super(const PredictionCareAlertState());

  final Ref _ref;
  Future<String?>? _inFlight;

  final Map<String, Future<void>> _actionInFlight = {};

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 兼容旧调用点：不再自动拉 daily（仅打日志）。
  Future<void> ensureLoaded({bool force = false}) async {
    AppDebugLog.careAlert(
      'ensureLoaded noop auto-daily disabled force=$force',
    );
  }

  /// 喂养工作台手动刷新：成功返回 null；失败返回可 Toast 文案。
  Future<String?> refreshDailyManual() {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      AppDebugLog.careAlert('manual refresh skipped not logged in');
      return Future.value('请先登录');
    }
    // 上一次 SSE 还在：立刻提示，不并入旧 Future，也不再打生成接口。
    if (_inFlight != null) {
      AppDebugLog.careAlert('manual refresh skipped in flight');
      return Future.value('上一次分析还在进行，请稍后再试');
    }
    return _inFlight ??= _refreshManualImpl().whenComplete(() {
      _inFlight = null;
    });
  }

  /// 进详情拉 latest 缓存（force=false，不扣日额度）；失败静默保留旧态。
  Future<void> hydrateLatestOnly() async {
    // 生成未结束时 latest 会把 loading 清掉，再进页会盖成历史列表。
    if (_inFlight != null) {
      AppDebugLog.careAlert('hydrate latest skipped in flight');
      return;
    }
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    var dn = _deviceNoOrNull();
    if (dn == null) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      dn = _deviceNoOrNull();
    }
    if (dn == null) return;
    try {
      final snap = await _ref
          .read(careAlertRepositoryProvider)
          .fetchDaily(deviceNo: dn, force: false);
      if (snap == null) return;
      // 等待 latest 期间用户已点分析：丢掉这次覆盖，保留思考态。
      if (_inFlight != null) {
        AppDebugLog.careAlert('hydrate latest dropped in flight');
        return;
      }
      state = PredictionCareAlertState(
        items: snap.items,
        loading: false,
        ready: true,
        failed: false,
        dayKey: careAlertShanghaiDayKey(),
        deviceNo: dn,
        usedToday: snap.usedToday,
        dailyLimit: snap.dailyLimit,
      );
      AppDebugLog.careAlert('hydrate latest ok count=${snap.items.length}');
    } catch (e) {
      AppDebugLog.careAlert('hydrate latest err=$e');
    }
  }

  Future<String?> _refreshManualImpl() async {
    var dn = _deviceNoOrNull();
    if (dn == null) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      dn = _deviceNoOrNull();
    }
    if (dn == null) {
      AppDebugLog.careAlert('manual refresh skipped no deviceNo');
      return '设备未就绪，请稍后重试';
    }

    await _ref.read(careAlertEligibilityStateProvider.notifier).ensureLoaded();
    final elig = _ref.read(careAlertEligibilityStateProvider);
    if (!elig.isQualified) {
      AppDebugLog.careAlert(
        'manual refresh skipped not qualified failed=${elig.failed}',
      );
      return '喂养资格未达标';
    }

    await _ref.read(featureCatalogStateProvider.notifier).ensureLoaded();
    final vip = await ensureVipSettled(_ref);
    final isVip = vip?.isVip == true;
    final careItem = _ref
        .read(featureCatalogStateProvider)
        .byId(kFeatureIdCareAlertSmartRemind);
    final unlocked = isFeatureEffectivelyUnlocked(item: careItem, isVip: isVip);
    final canUse = canAccessFeatureDetail(item: careItem, isVip: isVip);
    if (!canUse) {
      AppDebugLog.careAlert(
        'manual refresh skipped not accessible isVip=$isVip unlocked=$unlocked trial=${careItem?.trialAvailable}',
      );
      return '请先开通智能分析';
    }

    final day = careAlertShanghaiDayKey();
    state = state.copyWith(
      loading: true,
      failed: false,
      dayKey: day,
      deviceNo: dn,
      thinking: '',
    );
    try {
      var gotResult = false;
      await for (final ev in _ref
          .read(careAlertRepositoryProvider)
          .analyzeStream(deviceNo: dn)) {
        switch (ev) {
          case CareAlertThinkingDelta(:final content):
            state = state.copyWith(
              thinking: applyThinkingStageDelta(state.thinking, content),
            );
          case CareAlertResultEvent(:final snapshot):
            gotResult = true;
            state = PredictionCareAlertState(
              items: snapshot.items,
              loading: false,
              ready: true,
              failed: false,
              dayKey: snapshot.day.isNotEmpty ? snapshot.day : day,
              deviceNo: dn,
              usedToday: snapshot.usedToday,
              dailyLimit: snapshot.dailyLimit,
              thinking: '',
            );
            AppDebugLog.careAlert(
              'manual stream ok count=${snapshot.items.length}',
            );
          case CareAlertStreamErrorEvent(:final message):
            state = state.copyWith(
              loading: false,
              ready: false,
              failed: true,
              thinking: '',
            );
            AppDebugLog.careAlert('manual stream err=$message');
            return message.isNotEmpty ? message : '分析失败，请稍后重试';
        }
      }
      if (!gotResult) {
        state = state.copyWith(
          loading: false,
          ready: false,
          failed: true,
          thinking: '',
        );
        AppDebugLog.careAlert('manual stream ended without result');
        return '分析失败，请稍后重试';
      }
      return null;
    } on ApiBusinessException catch (e) {
      state = state.copyWith(
        loading: false,
        ready: false,
        failed: true,
        thinking: '',
      );
      AppDebugLog.careAlert('manual refresh business err=${e.code} ${e.message}');
      return e.message.isNotEmpty ? e.message : '分析失败，请稍后重试';
    } on ApiHttpException catch (e) {
      state = state.copyWith(
        loading: false,
        ready: false,
        failed: true,
        thinking: '',
      );
      AppDebugLog.careAlert('manual refresh http err=${e.statusCode}');
      return '分析失败，请稍后重试';
    } catch (e) {
      state = state.copyWith(
        loading: false,
        ready: false,
        failed: true,
        thinking: '',
      );
      AppDebugLog.careAlert('manual refresh err=$e');
      return '分析失败，请稍后重试';
    }
  }

  void removeLocally(String suggestionId) {
    final id = suggestionId.trim();
    if (id.isEmpty) return;
    state = state.copyWith(
      items: [
        for (final e in state.items)
          if (e.suggestionId != id) e,
      ],
    );
  }

  Future<void> ignoreSuggestion(CareAlertEventItem item) {
    final id = item.suggestionId.trim();
    if (id.isEmpty) return Future.value();
    return _actionInFlight.putIfAbsent(id, () async {
      removeLocally(id);
      final dn = _deviceNoOrNull() ?? state.deviceNo;
      if (dn.isEmpty) {
        AppDebugLog.careAlert('ignore skipped no deviceNo');
        return;
      }
      final deleted = await _ref.read(careAlertRepositoryProvider).deleteDailyItem(
        deviceNo: dn,
        suggestionId: id,
      );
      AppDebugLog.careAlert('ignore done deleted=$deleted (UI/cache only)');
    }).whenComplete(() {
      _actionInFlight.remove(id);
    });
  }

  Future<void> reportFollowUp(CareAlertEventItem item) {
    final id = item.suggestionId.trim();
    if (id.isEmpty) return Future.value();
    final key = 'fu:$id';
    return _actionInFlight.putIfAbsent(key, () async {
      AppDebugLog.careAlert('follow_up UI-only idLen=${id.length}');
    }).whenComplete(() {
      _actionInFlight.remove(key);
    });
  }

  void clear() {
    _inFlight = null;
    _actionInFlight.clear();
    state = const PredictionCareAlertState();
  }
}

final predictionCareAlertStateProvider = StateNotifierProvider<
    PredictionCareAlertNotifier, PredictionCareAlertState>((ref) {
  final n = PredictionCareAlertNotifier(ref);
  ref.listen(sessionProvider, (prev, next) {
    if (!next.isLoggedIn) n.clear();
  });
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    final dn = next.asData?.value?.trim();
    if (dn == null || dn.isEmpty) return;
    final prevDn = prev?.asData?.value?.trim();
    if (prevDn == dn) return;
    n.clear();
  });
  return n;
});

/// 兼容旧 FutureProvider：不再拉 daily。
final predictionCareAlertEnsureProvider = FutureProvider<void>((ref) async {
  AppDebugLog.careAlert('ensureProvider noop auto-daily disabled');
});

/// 是否允许尝试拉取：已登录 + deviceNo（资格由 cash eligibility 决定）。
bool careAlertSessionReady({
  required bool loggedIn,
  required String? deviceNo,
}) {
  if (!loggedIn) return false;
  final dn = deviceNo?.trim() ?? '';
  return dn.isNotEmpty;
}

/// 兼容旧名：不再要求「昨日有发生」；range 参数忽略。
bool careAlertDailyFetchGate({
  required bool loggedIn,
  required String? deviceNo,
  Object? range,
}) {
  return careAlertSessionReady(loggedIn: loggedIn, deviceNo: deviceNo);
}

final predictionCareAlertFetchAllowedProvider = Provider<bool>((ref) {
  return careAlertSessionReady(
    loggedIn: ref.watch(sessionProvider).isLoggedIn,
    deviceNo: ref.watch(deviceNoNotifierProvider).asData?.value,
  );
});

/// 过滤后的留意列表：信服务端快照 items；不做本地日键过期过滤。
final predictionCareAlertProvider = Provider<List<CareAlertEventItem>>((ref) {
  final st = ref.watch(predictionCareAlertStateProvider);
  // 仅 ready 且非加载/失败时展示；day/dayKey 不参与可见性。
  if (!st.ready || st.failed || st.loading) return const [];
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  if (disabled.isEmpty) return st.items;
  // 推演关闭的事件从列表中剔除。
  return [
    for (final e in st.items)
      if (!disabled.contains(e.eventId)) e,
  ];
});
