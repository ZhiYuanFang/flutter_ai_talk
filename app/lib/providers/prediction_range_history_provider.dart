import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/models.dart';
import '../data/prediction_range_history.dart';
import '../home_widget/home_widget_constants.dart';
import '../home_widget/home_widget_payload.dart';
import 'device_no_notifier.dart';
import 'repositories.dart';
import 'session_provider.dart';

@immutable
class PredictionRangeHistoryState {
  const PredictionRangeHistoryState({
    this.items = const [],
    this.loading = false,
    this.ready = false,
  });

  final List<HistoryRecord> items;
  final bool loading;
  final bool ready;

  PredictionRangeHistoryState copyWith({
    List<HistoryRecord>? items,
    bool? loading,
    bool? ready,
  }) {
    return PredictionRangeHistoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
    );
  }
}

/// 近 7 日预测历史（与喂养 homeHistory 隔离）。
class PredictionRangeHistoryNotifier
    extends StateNotifier<PredictionRangeHistoryState> {
  PredictionRangeHistoryNotifier(this._ref)
      : super(const PredictionRangeHistoryState());

  final Ref _ref;
  Future<void>? _inFlight;
  var _consecutiveFailures = 0;
  var _dirty = true;
  Timer? _debounce;

  bool get isCircuitOpen =>
      _consecutiveFailures >= HomeWidgetConstants.maxConsecutivePageFailures;

  String? _deviceNoOrNull() {
    final v = _ref.read(deviceNoNotifierProvider).asData?.value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Single-flight ensure；含 deviceNo 门控与 ready-空自愈。
  Future<void> ensureLoaded({bool force = false}) {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      state = const PredictionRangeHistoryState();
      return Future.value();
    }
    final existing = _inFlight;
    if (existing != null) {
      // 进行中：非 force 复用；force 等当前结束后再拉一轮
      if (!force) return existing;
      return existing.then((_) async {
        if (!_ref.read(sessionProvider).isLoggedIn) return;
        await ensureLoaded(force: true);
      });
    }
    return _inFlight = _ensureImpl(force: force).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _ensureImpl({required bool force}) async {
    // 已登录：dn 空则先灌本地缓存
    var dn = _deviceNoOrNull();
    if (dn == null) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      dn = _deviceNoOrNull();
    }

    // 假成功空列表：dn 已可用则强制重拉
    final healEmptyReady = state.ready &&
        state.items.isEmpty &&
        dn != null;
    final effectiveForce = force || healEmptyReady;

    if (!effectiveForce && state.ready && !_dirty && !state.loading) {
      return;
    }
    if (isCircuitOpen && !effectiveForce) {
      AppDebugLog.homeWidget('range ensure skipped circuit open');
      return;
    }
    if (dn == null) {
      AppDebugLog.homeWidget('range ensure skipped no deviceNo');
      // 解开无 dn 时留下的假 ready 空锁
      if (state.ready && state.items.isEmpty) {
        _dirty = true;
        state = const PredictionRangeHistoryState();
      } else {
        state = state.copyWith(loading: false);
      }
      return;
    }

    if (healEmptyReady) {
      AppDebugLog.homeWidget('range ensure heal empty-ready');
    }
    await _loadImpl(force: effectiveForce);
  }

  Future<void> _loadImpl({required bool force}) async {
    state = state.copyWith(loading: true);
    AppDebugLog.homeWidget('range load start force=$force');
    try {
      final feed = _ref.read(feedRepositoryProvider);
      final list = await fetchPredictionSevenDayHistory(feed);
      if (list == null) {
        _consecutiveFailures += 1;
        AppDebugLog.homeWidget(
          'range load fail consecutive=$_consecutiveFailures',
        );
        return;
      }
      _consecutiveFailures = 0;
      _dirty = false;
      state = PredictionRangeHistoryState(
        items: list,
        loading: false,
        ready: true,
      );
      AppDebugLog.homeWidget('range load ok count=${list.length}');
      await setWidgetHistoryDepthReady(true);
    } catch (e) {
      _consecutiveFailures += 1;
      AppDebugLog.homeWidget('range load err=$e');
    } finally {
      // 防止 filter/超时挂死后永久 loading
      if (state.loading) {
        state = state.copyWith(loading: false);
      }
    }
  }

  /// 历史变更后短防抖失效重拉。
  void scheduleInvalidation() {
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(ensureLoaded(force: true));
    });
  }

  void clear() {
    _debounce?.cancel();
    _debounce = null;
    _inFlight = null;
    _consecutiveFailures = 0;
    _dirty = true;
    state = const PredictionRangeHistoryState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final predictionRangeHistoryProvider = StateNotifierProvider<
    PredictionRangeHistoryNotifier, PredictionRangeHistoryState>((ref) {
  final n = PredictionRangeHistoryNotifier(ref);
  ref.listen(sessionProvider, (prev, next) {
    if (!next.isLoggedIn) n.clear();
  });
  // deviceNo 从空到有：补拉 range（覆盖 splash/ensure 抢跑）
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    final dn = next.asData?.value?.trim();
    if (dn == null || dn.isEmpty) return;
    final prevDn = prev?.asData?.value?.trim();
    if (prevDn != null && prevDn.isNotEmpty) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    unawaited(n.ensureLoaded(force: true));
  });
  return n;
});

/// 供 UI / 小组件 await 的 ensure FutureProvider（内部 single-flight）。
final predictionRangeEnsureProvider = FutureProvider<void>((ref) async {
  await ref.read(predictionRangeHistoryProvider.notifier).ensureLoaded();
});
