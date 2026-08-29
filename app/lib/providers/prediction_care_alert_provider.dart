import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/care_alert_repository.dart';
import '../data/feature_unlock_models.dart';
import '../data/feature_unlock_repository.dart';
import '../data/prediction_care_alert.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'forecast_toggle_provider.dart';
import 'session_provider.dart';
import 'smart_prediction_provider.dart';

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

/// 日拉取状态：原始服务端列表（未做推演过滤）。
class PredictionCareAlertState {
  const PredictionCareAlertState({
    this.items = const [],
    this.loading = false,
    this.ready = false,
    this.failed = false,
    this.dayKey = '',
    this.deviceNo = '',
  });

  final List<CareAlertEventItem> items;
  final bool loading;
  final bool ready;
  final bool failed;
  final String dayKey;
  final String deviceNo;

  PredictionCareAlertState copyWith({
    List<CareAlertEventItem>? items,
    bool? loading,
    bool? ready,
    bool? failed,
    String? dayKey,
    String? deviceNo,
  }) {
    return PredictionCareAlertState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      failed: failed ?? this.failed,
      dayKey: dayKey ?? this.dayKey,
      deviceNo: deviceNo ?? this.deviceNo,
    );
  }
}

/// 日缓存拉取：须先 cash 资格合格；single-flight + 同日成功幂等。
class PredictionCareAlertNotifier
    extends StateNotifier<PredictionCareAlertState> {
  PredictionCareAlertNotifier(this._ref)
      : super(const PredictionCareAlertState());

  final Ref _ref;
  Future<void>? _inFlight;

  final Map<String, Future<void>> _actionInFlight = {};

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 显式 ensure：先资格，合格再拉日列表。
  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      AppDebugLog.careAlert('ensure skipped not logged in');
      state = const PredictionCareAlertState();
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
      AppDebugLog.careAlert('ensure skipped no deviceNo');
      state = const PredictionCareAlertState();
      return;
    }

    // 先确保 cash 喂养资格（替代「昨日有发生」）。
    await _ref
        .read(careAlertEligibilityStateProvider.notifier)
        .ensureLoaded(force: force);
    final elig = _ref.read(careAlertEligibilityStateProvider);
    if (!elig.isQualified) {
      AppDebugLog.careAlert(
        'ensure skipped not qualified failed=${elig.failed} '
        'ready=${elig.ready}',
      );
      // 清空日列表；UI 用 eligibility 展示进度卡。
      state = const PredictionCareAlertState();
      return;
    }

    final day = careAlertShanghaiDayKey();
    if (!force &&
        state.ready &&
        !state.failed &&
        state.dayKey == day &&
        state.deviceNo == dn &&
        !state.loading) {
      return;
    }

    state = state.copyWith(
      loading: true,
      failed: false,
      dayKey: day,
      deviceNo: dn,
    );
    try {
      final list =
          await _ref.read(careAlertRepositoryProvider).fetchDaily(deviceNo: dn);
      if (list == null) {
        state = PredictionCareAlertState(
          items: const [],
          loading: false,
          ready: false,
          failed: true,
          dayKey: day,
          deviceNo: dn,
        );
        AppDebugLog.careAlert('ensure fail');
        return;
      }
      state = PredictionCareAlertState(
        items: list,
        loading: false,
        ready: true,
        failed: false,
        dayKey: day,
        deviceNo: dn,
      );
    } catch (e) {
      state = PredictionCareAlertState(
        items: const [],
        loading: false,
        ready: false,
        failed: true,
        dayKey: day,
        deviceNo: dn,
      );
      AppDebugLog.careAlert('ensure err=$e');
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

final predictionCareAlertEnsureProvider = FutureProvider<void>((ref) async {
  await ref.read(predictionCareAlertStateProvider.notifier).ensureLoaded();
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

final predictionCareAlertProvider = Provider<List<CareAlertEventItem>>((ref) {
  final now =
      ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
  final day = careAlertShanghaiDayKey(now);
  final st = ref.watch(predictionCareAlertStateProvider);
  final elig = ref.watch(careAlertEligibilityStateProvider);
  final loggedIn = ref.watch(sessionProvider).isLoggedIn;
  final dn =
      ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  final canFetch = careAlertSessionReady(loggedIn: loggedIn, deviceNo: dn) &&
      elig.isQualified;
  if (canFetch && st.ready && st.dayKey.isNotEmpty && st.dayKey != day) {
    Future.microtask(() {
      ref.invalidate(predictionCareAlertEnsureProvider);
      unawaited(
        ref
            .read(predictionCareAlertStateProvider.notifier)
            .ensureLoaded(force: true),
      );
    });
    return const [];
  }
  if (!st.ready || st.failed || st.loading) return const [];
  final disabled =
      ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
  if (disabled.isEmpty) return st.items;
  return [
    for (final e in st.items)
      if (!disabled.contains(e.eventId)) e,
  ];
});
