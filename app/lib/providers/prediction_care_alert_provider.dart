import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/care_alert_repository.dart';
import '../data/prediction_care_alert.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'forecast_toggle_provider.dart';
import 'prediction_range_history_provider.dart';
import 'session_provider.dart';
import 'smart_prediction_provider.dart';

/// Care-alert API 仓储。
final careAlertRepositoryProvider = Provider<CareAlertRepository>((ref) {
  return CareAlertRepository(ref.watch(authorizedApiClientProvider));
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

/// 日缓存拉取：single-flight + 同日成功幂等；失败不熔断，下次 ensure 再试。
class PredictionCareAlertNotifier
    extends StateNotifier<PredictionCareAlertState> {
  PredictionCareAlertNotifier(this._ref)
      : super(const PredictionCareAlertState());

  final Ref _ref;
  Future<void>? _inFlight;

  /// suggestionId → 进行中的忽略/反馈 Future（用户点击去重）
  final Map<String, Future<void>> _actionInFlight = {};

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 显式 ensure（预测页可见时调用）；provider create 不自动打 HTTP。
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

    final day = careAlertShanghaiDayKey();
    // 同日同设备已成功：幂等跳过（除非 force）
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

  /// 乐观本地移除（忽略后跑马灯立刻更新）。
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

  /// 忽略：本地移除 + DELETE 日缓存项；不打飞轮、不打 Python。
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

  /// 追问：仅本地标记；不打飞轮、不打 Python（调用方负责打开树洞）。
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
  // deviceNo 变更：清空旧列表，等待下次 ensure
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    final dn = next.asData?.value?.trim();
    if (dn == null || dn.isEmpty) return;
    final prevDn = prev?.asData?.value?.trim();
    if (prevDn == dn) return;
    n.clear();
  });
  return n;
});

/// UI ensure FutureProvider（内部 single-flight）；仅显式 watch/invalidate 时拉取。
final predictionCareAlertEnsureProvider = FutureProvider<void>((ref) async {
  await ref.read(predictionCareAlertStateProvider.notifier).ensureLoaded();
});

/// 是否允许 care-alert 日拉取（已登录 + deviceNo + range 真历史非空）。
final predictionCareAlertFetchAllowedProvider = Provider<bool>((ref) {
  if (!ref.watch(sessionProvider).isLoggedIn) return false;
  final dn = ref.watch(deviceNoNotifierProvider).asData?.value?.trim();
  if (dn == null || dn.isEmpty) return false;
  final range = ref.watch(predictionRangeHistoryProvider);
  if (!range.ready || range.loading) return false;
  return range.items.isNotEmpty;
});

/// 推演关闭过滤后的展示列表；加载/失败时为空（卡片仍由 state 驱动空态/错误态）。
/// 不再因 watch 本 provider 而自动 ensure（冷态禁止副作用 HTTP）。
final predictionCareAlertProvider = Provider<List<CareAlertEventItem>>((ref) {
  // 时钟用于跨上海自然日失效重拉
  final now =
      ref.watch(predictionClockProvider).asData?.value ?? DateTime.now();
  final day = careAlertShanghaiDayKey(now);
  final st = ref.watch(predictionCareAlertStateProvider);
  final range = ref.watch(predictionRangeHistoryProvider);
  final loggedIn = ref.watch(sessionProvider).isLoggedIn;
  final dn =
      ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  final canFetch = loggedIn &&
      dn.isNotEmpty &&
      range.ready &&
      !range.loading &&
      range.items.isNotEmpty;
  if (canFetch && st.ready && st.dayKey.isNotEmpty && st.dayKey != day) {
    // 日切且具备拉取条件：隐藏面板并 force ensure
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
