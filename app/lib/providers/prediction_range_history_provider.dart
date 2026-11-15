import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../home_widget/home_widget_sync.dart';
import 'home_history_notifier.dart';
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

/// 兼容壳：远端 ensure 已并入 [homeHistoryProvider] 统一池；不再独立 HTTP。
class PredictionRangeHistoryNotifier
    extends StateNotifier<PredictionRangeHistoryState> {
  PredictionRangeHistoryNotifier(this._ref)
      : super(const PredictionRangeHistoryState()) {
    _ref.listen<HomeHistoryState>(homeHistoryProvider, (_, next) {
      state = PredictionRangeHistoryState(
        items: next.items,
        loading: next.seeding,
        ready: next.initialLoadDone,
      );
    }, fireImmediately: true);
  }

  final Ref _ref;

  /// 委托统一池近 7 日种子。
  Future<void> ensureLoaded({bool force = false}) async {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      state = const PredictionRangeHistoryState(ready: true);
      return;
    }
    await _ref.read(homeHistoryProvider.notifier).seedSevenDayHistory(
          force: force,
          preserveOlderOutsideWindow: true,
        );
  }

  Future<bool> reloadForUserPull() async {
    return _ref
        .read(homeHistoryProvider.notifier)
        .refreshFromRemote(preserveLoadedDepth: true);
  }

  /// 统一池变更已直接 sync widget；避免旧调用方再拉 HTTP。
  void scheduleInvalidation() {
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    unawaited(scheduleHomeWidgetSync(_ref));
  }

  void removeItemById(String id) {}

  void clear() {
    state = const PredictionRangeHistoryState(ready: true);
  }
}

final predictionRangeHistoryProvider = StateNotifierProvider<
    PredictionRangeHistoryNotifier, PredictionRangeHistoryState>((ref) {
  return PredictionRangeHistoryNotifier(ref);
});

/// 预测页/tip：等待统一池种子（不再独立 range HTTP）。
final predictionRangeEnsureProvider = FutureProvider<void>((ref) async {
  await ref.read(homeHistoryProvider.notifier).seedSevenDayHistory(
        force: false,
        preserveOlderOutsideWindow: true,
      );
});
