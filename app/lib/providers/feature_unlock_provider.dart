import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/cash_apple_iap_repository.dart';
import '../data/feature_unlock_models.dart';
import '../data/feature_unlock_repository.dart';
import '../services/feature_payment_service.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

final featureUnlockRepositoryProvider = Provider<FeatureUnlockRepository>((ref) {
  return FeatureUnlockRepository(ref.watch(authorizedApiClientProvider));
});

/// 功能/小智 Apple 验单（历史 vip/apple/verify；非 VIP 履约）。
final cashAppleIapRepositoryProvider = Provider<CashAppleIapRepository>((ref) {
  return CashAppleIapRepository(ref.watch(authorizedApiClientProvider));
});

final featurePaymentServiceProvider = Provider<FeaturePaymentService>((ref) {
  return FeaturePaymentService(
    ref.watch(featureUnlockRepositoryProvider),
    ref.watch(cashAppleIapRepositoryProvider),
  );
});

/// catalog 拉取态（cache-first；provider create 不自动 HTTP）。
class FeatureCatalogState {
  const FeatureCatalogState({
    this.items = const [],
    this.inviteGroupQrUrl = '',
    this.loading = false,
    this.ready = false,
    this.failed = false,
    this.deviceNo = '',
    this.failStreak = 0,
  });

  final List<FeatureCatalogItem> items;
  final String inviteGroupQrUrl;
  final bool loading;
  final bool ready;
  final bool failed;
  final String deviceNo;
  final int failStreak;

  FeatureCatalogState copyWith({
    List<FeatureCatalogItem>? items,
    String? inviteGroupQrUrl,
    bool? loading,
    bool? ready,
    bool? failed,
    String? deviceNo,
    int? failStreak,
  }) {
    return FeatureCatalogState(
      items: items ?? this.items,
      inviteGroupQrUrl: inviteGroupQrUrl ?? this.inviteGroupQrUrl,
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      failed: failed ?? this.failed,
      deviceNo: deviceNo ?? this.deviceNo,
      failStreak: failStreak ?? this.failStreak,
    );
  }

  /// 预测永久可开槽位数；缺项按 0。
  /// 语义：解锁「当前排序列表」前 N 行（槽位），非固定 eventId。
  /// `-1` 为历史哨兵（全开）；本变更后 catalog 预期不再下发。
  int get predictionAllowedCount {
    for (final it in items) {
      if (it.featureId == kFeatureIdPredictionUnlock) {
        return it.allowedCount ?? 0;
      }
    }
    return 0;
  }

  /// 预测默认免费槽位数；旧服缺字段为 null（文案不得说「默认」）。
  int? get predictionDefaultCount {
    for (final it in items) {
      if (it.featureId == kFeatureIdPredictionUnlock) {
        return it.defaultCount;
      }
    }
    return null;
  }

  /// 预测行是否在数量锁下已解锁（不含 VIP；VIP 由调用方另判）。
  /// [realIndex] 为当前展示列表排序后的下标；重排后槽位跟下标走。
  /// [allowedCount] < 0（哨兵 -1）表示全开。
  static bool predictionIndexUnlocked(int realIndex, int allowedCount) {
    if (allowedCount < 0) return true;
    return realIndex < allowedCount;
  }

  FeatureCatalogItem? byId(String featureId) {
    final id = featureId.trim();
    for (final it in items) {
      if (it.featureId == id) return it;
    }
    return null;
  }
}

class FeatureCatalogNotifier extends StateNotifier<FeatureCatalogState> {
  FeatureCatalogNotifier(this._ref) : super(const FeatureCatalogState());

  final Ref _ref;
  Future<void>? _inFlight;

  /// 连续失败达到阈值后短熔断（秒）。
  static const _circuitFailThreshold = 3;
  static const _circuitCooldown = Duration(seconds: 60);
  DateTime? _circuitUntil;

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 显式 ensure；create 不自动调用。
  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      AppDebugLog.featureUnlock('catalog ensure skipped not logged in');
      state = const FeatureCatalogState();
      return Future.value();
    }
    if (!force &&
        _circuitUntil != null &&
        DateTime.now().isBefore(_circuitUntil!)) {
      AppDebugLog.featureUnlock('catalog ensure skipped circuit');
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
      AppDebugLog.featureUnlock('catalog ensure skipped no deviceNo');
      state = const FeatureCatalogState();
      return;
    }

    if (!force &&
        state.ready &&
        !state.failed &&
        state.deviceNo == dn &&
        state.items.isNotEmpty) {
      // 缓存命中：必须 return，不得再写 loading（否则 build 期调用会炸 Riverpod）
      AppDebugLog.featureUnlock('catalog ensure skip same device cache');
      return;
    }

    state = state.copyWith(loading: true, failed: false, deviceNo: dn);
    try {
      final payload =
          await _ref.read(featureUnlockRepositoryProvider).fetchCatalog();
      state = FeatureCatalogState(
        items: payload.items,
        inviteGroupQrUrl: payload.inviteGroupQrUrl,
        loading: false,
        ready: true,
        failed: false,
        deviceNo: dn,
        failStreak: 0,
      );
      _circuitUntil = null;
      AppDebugLog.featureUnlock(
        'catalog ready count=${payload.items.length} '
        'predictionAllowed=${state.predictionAllowedCount}',
      );
    } catch (e) {
      final streak = state.failStreak + 1;
      AppDebugLog.featureUnlock('catalog ensure fail streak=$streak err=$e');
      state = state.copyWith(
        loading: false,
        failed: true,
        failStreak: streak,
        // 保留旧 items 作 cache-first
      );
      if (streak >= _circuitFailThreshold) {
        _circuitUntil = DateTime.now().add(_circuitCooldown);
      }
    }
  }

  Future<void> refresh() => ensureLoaded(force: true);
}

final featureCatalogStateProvider =
    StateNotifierProvider<FeatureCatalogNotifier, FeatureCatalogState>((ref) {
  return FeatureCatalogNotifier(ref);
});

/// UCG eligibility 拉取态。
class UcgEligibilityState {
  const UcgEligibilityState({
    this.data,
    this.loading = false,
    this.ready = false,
    this.failed = false,
    this.deviceNo = '',
    this.failStreak = 0,
  });

  final UcgEligibility? data;
  final bool loading;
  final bool ready;
  final bool failed;
  final String deviceNo;
  final int failStreak;

  /// fail-closed：仅明确 qualified=true 才放行。
  bool get isQualified => data?.qualified == true;

  UcgEligibilityState copyWith({
    UcgEligibility? data,
    bool? loading,
    bool? ready,
    bool? failed,
    String? deviceNo,
    int? failStreak,
    bool clearData = false,
  }) {
    return UcgEligibilityState(
      data: clearData ? null : (data ?? this.data),
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      failed: failed ?? this.failed,
      deviceNo: deviceNo ?? this.deviceNo,
      failStreak: failStreak ?? this.failStreak,
    );
  }
}

class UcgEligibilityNotifier extends StateNotifier<UcgEligibilityState> {
  UcgEligibilityNotifier(this._ref) : super(const UcgEligibilityState());

  final Ref _ref;
  Future<void>? _inFlight;
  static const _circuitFailThreshold = 3;
  static const _circuitCooldown = Duration(seconds: 60);
  DateTime? _circuitUntil;

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      AppDebugLog.featureUnlock('eligibility ensure skipped not logged in');
      state = const UcgEligibilityState();
      return Future.value();
    }
    // 已 ready 且非强制：短路，避免每次滑入 UCG 重复资格 HTTP
    if (!force && state.ready && state.data != null) {
      return Future.value();
    }
    if (!force &&
        _circuitUntil != null &&
        DateTime.now().isBefore(_circuitUntil!)) {
      AppDebugLog.featureUnlock('eligibility ensure skipped circuit');
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
      AppDebugLog.featureUnlock('eligibility ensure skipped no deviceNo');
      state = const UcgEligibilityState();
      return;
    }

    state = state.copyWith(loading: true, failed: false, deviceNo: dn);
    try {
      final e =
          await _ref.read(featureUnlockRepositoryProvider).fetchUcgEligibility();
      state = UcgEligibilityState(
        data: e,
        loading: false,
        ready: true,
        failed: false,
        deviceNo: dn,
        failStreak: 0,
      );
      _circuitUntil = null;
    } catch (err) {
      final streak = state.failStreak + 1;
      AppDebugLog.featureUnlock('eligibility ensure fail streak=$streak err=$err');
      state = state.copyWith(
        loading: false,
        failed: true,
        failStreak: streak,
      );
      if (streak >= _circuitFailThreshold) {
        _circuitUntil = DateTime.now().add(_circuitCooldown);
      }
    }
  }

  Future<void> refresh() => ensureLoaded(force: true);
}

final ucgEligibilityStateProvider =
    StateNotifierProvider<UcgEligibilityNotifier, UcgEligibilityState>((ref) {
  return UcgEligibilityNotifier(ref);
});

/// 预测 Pro 喂养资格（字段同构 UCG；不挡免费亲和预测/进度）。
class PredictProEligibilityNotifier extends StateNotifier<UcgEligibilityState> {
  PredictProEligibilityNotifier(this._ref) : super(const UcgEligibilityState());

  final Ref _ref;
  Future<void>? _inFlight;
  static const _circuitFailThreshold = 3;
  static const _circuitCooldown = Duration(seconds: 60);
  DateTime? _circuitUntil;

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      AppDebugLog.featureUnlock('predict-pro eligibility skipped not logged in');
      state = const UcgEligibilityState();
      return Future.value();
    }
    if (!force && state.ready && state.data != null) {
      return Future.value();
    }
    if (!force &&
        _circuitUntil != null &&
        DateTime.now().isBefore(_circuitUntil!)) {
      AppDebugLog.featureUnlock('predict-pro eligibility skipped circuit');
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
      AppDebugLog.featureUnlock('predict-pro eligibility skipped no deviceNo');
      state = const UcgEligibilityState();
      return;
    }

    state = state.copyWith(loading: true, failed: false, deviceNo: dn);
    try {
      final e = await _ref
          .read(featureUnlockRepositoryProvider)
          .fetchPredictProEligibility();
      state = UcgEligibilityState(
        data: e,
        loading: false,
        ready: true,
        failed: false,
        deviceNo: dn,
        failStreak: 0,
      );
      _circuitUntil = null;
    } catch (err) {
      final streak = state.failStreak + 1;
      AppDebugLog.featureUnlock(
        'predict-pro eligibility fail streak=$streak err=$err',
      );
      state = state.copyWith(
        loading: false,
        failed: true,
        failStreak: streak,
      );
      if (streak >= _circuitFailThreshold) {
        _circuitUntil = DateTime.now().add(_circuitCooldown);
      }
    }
  }

  Future<void> refresh() => ensureLoaded(force: true);
}

final predictProEligibilityStateProvider =
    StateNotifierProvider<PredictProEligibilityNotifier, UcgEligibilityState>(
        (ref) {
  return PredictProEligibilityNotifier(ref);
});

/// 从 catalog 态取预测两档项。
({FeatureCatalogItem? basic, FeatureCatalogItem? pro}) predictCapabilityItems(
  FeatureCatalogState catalog,
) {
  return (
    basic: catalog.byId(kFeatureIdPredictCapabilityBasic),
    pro: catalog.byId(kFeatureIdPredictCapabilityPro),
  );
}

/// 预测开通态结算相位：syncing 时不得当未开通触发提醒副作用。
enum PredictEntitlementSettlePhase {
  /// catalog 尚未结案。
  syncing,
  /// 已结案（含 fail-closed）。
  ready,
}

/// 已登录已绑定：catalog 未 ready/未失败结案 → syncing。
final predictEntitlementSettlePhaseProvider =
    Provider<PredictEntitlementSettlePhase>((ref) {
  final loggedIn = ref.watch(sessionProvider).isLoggedIn;
  final dn =
      ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  if (!loggedIn || dn.isEmpty) {
    return PredictEntitlementSettlePhase.ready;
  }
  final catalog = ref.watch(featureCatalogStateProvider);
  // ready 且 device 对齐，或 failed 已结案（避免永久同步中）
  final catalogSettled =
      (catalog.ready && catalog.deviceNo == dn) || catalog.failed;
  if (!catalogSettled) {
    return PredictEntitlementSettlePhase.syncing;
  }
  return PredictEntitlementSettlePhase.ready;
});
