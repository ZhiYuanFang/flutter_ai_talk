import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/feature_unlock_models.dart';
import '../data/feature_unlock_repository.dart';
import '../services/feature_payment_service.dart';
import 'authorized_api_client_provider.dart';
import 'cash_vip_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

final featureUnlockRepositoryProvider = Provider<FeatureUnlockRepository>((ref) {
  return FeatureUnlockRepository(ref.watch(authorizedApiClientProvider));
});

final featurePaymentServiceProvider = Provider<FeaturePaymentService>((ref) {
  return FeaturePaymentService(
    ref.watch(featureUnlockRepositoryProvider),
    ref.watch(cashVipRepositoryProvider),
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
      AppDebugLog.featureUnlock('catalog ensure skip same device cache');
      // 仍后台轻刷一次（非 force 幂等缓存展示后刷新）
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

/// 目录功能是否有效开通（含 isVip 覆盖；不含 UCG）。
/// 预测：仅当永久条数达服务端非叶子 total 才算「已全部激活」；VIP 不抬 Hub 库存态。
bool isFeatureEffectivelyUnlocked({
  required FeatureCatalogItem? item,
  required bool isVip,
}) {
  if (item?.featureId == kFeatureIdPredictionUnlock) {
    return item?.isPredictionFullyActivated == true;
  }
  if (isVip) return true;
  return item?.unlocked == true;
}

/// 预测累加 CTA：未达非叶子天花板即展示（VIP 不隐藏）；与列表可见行数无关。
bool shouldShowPredictionAccumulationCtas(FeatureCatalogItem item) {
  return !item.isPredictionFullyActivated;
}

/// 展示用开通方式：设备 grant 优先，否则 VIP→月卡。
String displayUnlockMethod({
  required FeatureCatalogItem? item,
  required bool isVip,
}) {
  if (item != null && item.unlocked && item.unlockMethod.trim().isNotEmpty) {
    return item.unlockMethod.trim();
  }
  if (isVip) return 'vip';
  if (item != null && item.unlocked) return item.unlockMethod;
  return '';
}
