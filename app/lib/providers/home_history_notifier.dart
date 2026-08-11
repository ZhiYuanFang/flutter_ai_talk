import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/history_list_page.dart';
import '../data/history_mapper.dart';
import '../data/home_history_store.dart';
import '../data/home_history_memory_cache.dart';
import '../data/models.dart';
import '../home_widget/home_widget_sync.dart';
import 'device_no_notifier.dart';
import 'prediction_range_history_provider.dart';
import 'repositories.dart';
import 'session_provider.dart';

@immutable
class HomeHistoryState {
  const HomeHistoryState({
    this.items = const [],
    this.initialLoadDone = false,
    this.total = 0,
    this.highestPageLoaded = 0,
    this.loadingMore = false,
  });

  final List<HistoryRecord> items;
  final bool initialLoadDone;
  final int total;
  final int highestPageLoaded;
  final bool loadingMore;

  bool get hasMore {
    if (highestPageLoaded <= 0) return false;
    if (total > 0) {
      return highestPageLoaded * kHomeHistoryPageSize < total;
    }
    return items.length >= highestPageLoaded * kHomeHistoryPageSize;
  }

  HomeHistoryState copyWith({
    List<HistoryRecord>? items,
    bool? initialLoadDone,
    int? total,
    int? highestPageLoaded,
    bool? loadingMore,
  }) {
    return HomeHistoryState(
      items: items ?? this.items,
      initialLoadDone: initialLoadDone ?? this.initialLoadDone,
      total: total ?? this.total,
      highestPageLoaded: highestPageLoaded ?? this.highestPageLoaded,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class HomeHistoryNotifier extends StateNotifier<HomeHistoryState> {
  HomeHistoryNotifier(this._ref, HomeHistoryState initialState)
      : super(initialState) {
    unawaited(_warmFromDisk());
  }

  final Ref _ref;
  Future<void>? _warmFuture;
  Future<bool>? _loadPageInFlight;
  Future<void>? _refreshFuture;
  var _flyAnimationFrozen = false;
  var _consecutiveLoadMoreFailures = 0;
  final List<void Function()> _queuedWhileFlyFrozen = [];

  /// 切号/注销递增；in-flight 写回比对后丢弃。
  var _epoch = 0;

  bool _isStale(int epoch) => epoch != _epoch;

  int get consecutiveLoadMoreFailures => _consecutiveLoadMoreFailures;

  bool get isLoadMoreCircuitOpen =>
      _consecutiveLoadMoreFailures >= HomeWidgetConstants.maxConsecutivePageFailures;

  void resetLoadMoreCircuit() {
    _consecutiveLoadMoreFailures = 0;
  }

  /// 飞行动画期间冻结列表变更，结束后再依次应用队列。
  void setFlyAnimationFrozen(bool frozen) {
    if (_flyAnimationFrozen == frozen) return;
    _flyAnimationFrozen = frozen;
    if (!frozen) {
      _flushQueuedWhileFlyFrozen();
    }
  }

  bool get isFlyAnimationFrozen => _flyAnimationFrozen;

  void _flushQueuedWhileFlyFrozen() {
    while (_queuedWhileFlyFrozen.isNotEmpty) {
      final batch = List<void Function()>.from(_queuedWhileFlyFrozen);
      _queuedWhileFlyFrozen.clear();
      for (final op in batch) {
        op();
      }
    }
  }

  bool _enqueueIfFrozen(void Function() op) {
    if (!_flyAnimationFrozen) return false;
    _queuedWhileFlyFrozen.add(op);
    return true;
  }

  void _applyState(HomeHistoryState next, {required int epoch}) {
    if (_isStale(epoch)) return;
    state = next;
    HomeHistoryMemoryCache.update(_deviceNo(), next.items);
  }

  void _applyItems(
    List<HistoryRecord> items, {
    int? total,
    int? highestPageLoaded,
    required int epoch,
  }) {
    _applyState(
      state.copyWith(
        items: items,
        total: total,
        highestPageLoaded: highestPageLoaded,
      ),
      epoch: epoch,
    );
  }

  /// 已登录但无 deviceNo：强制空列表，避免残留上一账号 items。
  void _clearItemsForUnboundSession({required int epoch}) {
    if (_isStale(epoch)) return;
    HomeHistoryMemoryCache.clear();
    state = const HomeHistoryState(initialLoadDone: true);
  }

  Future<void> _warmFromDisk() {
    return _warmFuture ??= _loadWarmFromDisk();
  }

  Future<void> _loadWarmFromDisk() async {
    final epoch = _epoch;
    if (state.items.isNotEmpty) return;
    if (!_ref.read(sessionProvider).isLoggedIn) {
      if (!state.initialLoadDone) {
        state = state.copyWith(initialLoadDone: true);
      }
      return;
    }
    var dn = _ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      if (_isStale(epoch)) return;
      dn = _ref.read(deviceNoNotifierProvider).asData?.value;
    }
    if (dn == null || dn.isEmpty) {
      _clearItemsForUnboundSession(epoch: epoch);
      return;
    }
    final cached = await HomeHistoryStore.loadSnapshot(dn);
    if (_isStale(epoch)) return;
    if (cached.items.isEmpty) return;
    _applyState(
      state.copyWith(
        items: cached.items,
        total: cached.total,
        highestPageLoaded: cached.highestPageLoaded,
      ),
      epoch: epoch,
    );
  }

  String? _deviceNo() => _ref.read(deviceNoNotifierProvider).asData?.value;

  Future<void> loadFromDisk() async {
    if (state.items.isNotEmpty) return;
    await _warmFromDisk();
  }

  /// Splash 本地 hydrate：读盘后若有缓存则标记 initialLoadDone，避免有磁盘数据仍转圈。
  Future<void> hydrateFromDiskForSplash() async {
    await loadFromDisk();
    if (state.items.isNotEmpty && !state.initialLoadDone) {
      state = state.copyWith(initialLoadDone: true);
    }
  }

  void markInitialLoadComplete() {
    if (state.initialLoadDone) return;
    state = state.copyWith(initialLoadDone: true);
  }

  /// 切号/注销：作废 in-flight、清飞入队列、清空进程内存与 notifier 状态。
  void clearForSignOut() {
    _epoch++;
    _queuedWhileFlyFrozen.clear();
    _warmFuture = null;
    _refreshFuture = null;
    _loadPageInFlight = null;
    _flyAnimationFrozen = false;
    HomeHistoryMemoryCache.clear();
    state = const HomeHistoryState(initialLoadDone: true);
  }

  HomeHistoryCacheSnapshot _currentSnapshot() {
    return HomeHistoryCacheSnapshot(
      items: state.items,
      total: state.total > 0 ? state.total : state.items.length,
      highestPageLoaded: state.highestPageLoaded > 0
          ? state.highestPageLoaded
          : (state.items.isEmpty ? 0 : 1),
    );
  }

  Future<void> persistToDisk() async {
    final epoch = _epoch;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return;
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    final snapshot = _currentSnapshot();
    if (_isStale(epoch)) return;
    await HomeHistoryStore.saveSnapshot(dn, snapshot);
    // wipe 后迟到写入：再清盘，避免旧 deviceNo 文件复活
    if (_isStale(epoch) || _deviceNo() != dn) {
      await HomeHistoryStore.clearAll();
    }
  }

  void setItems(List<HistoryRecord> items, {bool persist = true, String source = 'setItems'}) {
    if (_enqueueIfFrozen(() => setItems(items, persist: persist, source: source))) {
      return;
    }
    _setItemsNow(items, persist: persist);
  }

  void _setItemsNow(List<HistoryRecord> items, {bool persist = true}) {
    final epoch = _epoch;
    if (_isStale(epoch)) return;
    _applyItems(items, epoch: epoch);
    if (_isStale(epoch)) return;
    if (_ref.read(sessionProvider).isLoggedIn) {
      // 喂养历史变更 → 失效预测 range（防抖重拉），再推小组件
      _ref.read(predictionRangeHistoryProvider.notifier).scheduleInvalidation();
      // 传入快照，避免 sync 内 read(homeHistoryProvider) 自依赖
      unawaited(scheduleHomeWidgetSync(_ref, history: items));
    }
    if (persist) unawaited(persistToDisk());
  }

  /// 结束计时时立即落 state（绕过飞行动画冻结），并触发小组件 sync。
  void replaceRecordImmediate(HistoryRecord record) {
    final next = state.items.map((e) => e.id == record.id ? record : e).toList();
    _setItemsNow(next);
  }

  void upsertRecord(HistoryRecord record) {
    if (_enqueueIfFrozen(() => upsertRecord(record))) return;
    final idx = state.items.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      final next = [...state.items];
      next[idx] = record;
      setItems(next, source: 'wsUpsert merge id=${record.id}');
      return;
    }
    final pendingIdx = state.items.indexWhere(
      (e) => isPendingHistoryId(e.id) && historyRecordMatchesPendingAdd(e, record),
    );
    if (pendingIdx >= 0) {
      final pendingId = state.items[pendingIdx].id;
      final next = state.items
          .map((e) => e.id == pendingId ? record : e)
          .toList();
      setItems(next, source: 'wsUpsert pending->${record.id}');
      return;
    }
    setItems([...state.items, record], source: 'wsUpsert id=${record.id}');
  }

  void insertOptimistic(HistoryRecord record) {
    // 防 WS 与 HTTP 竞态：同 id 已存在则合并，不追加第二行
    final idx = state.items.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      final next = [...state.items];
      next[idx] = record;
      _setItemsNow(next);
      return;
    }
    _setItemsNow([...state.items, record]);
  }

  void replaceRecordId(String fromId, String toId) {
    if (_enqueueIfFrozen(() => replaceRecordId(fromId, toId))) return;
    final items = state.items;
    final fromIdx = items.indexWhere((e) => e.id == fromId);
    if (fromIdx < 0) return;

    final from = items[fromIdx];
    final toIdx = items.indexWhere((e) => e.id == toId);
    final updated = _recordWithReplacedId(from, toId);

    if (toIdx >= 0 && toIdx != fromIdx) {
      setItems(
        items.where((e) => e.id != fromId).toList(),
        source: 'replaceRecordId drop pending $fromId (had $toId)',
      );
      return;
    }

    final next = items.map((e) => e.id == fromId ? updated : e).toList();
    setItems(next, source: 'replaceRecordId $fromId->$toId');
  }

  HistoryRecord _recordWithReplacedId(HistoryRecord record, String serverId) {
    final p = Map<String, Object?>.from(record.rawPayload);
    final parsed = int.tryParse(serverId);
    p['id'] = parsed ?? serverId;
    return HistoryRecord(
      id: serverId,
      createdAt: record.createdAt,
      eventName: record.eventName,
      action: record.action,
      rawPayload: p,
    );
  }

  void removeById(String id) => removeRecord(id);

  void removeRecord(String id) {
    if (_enqueueIfFrozen(() => removeRecord(id))) return;
    setItems(
      state.items.where((e) => e.id != id).toList(),
      source: 'wsRemove id=$id',
    );
  }

  void replaceRecord(HistoryRecord record) {
    if (_enqueueIfFrozen(() => replaceRecord(record))) return;
    setItems(
      state.items.map((e) => e.id == record.id ? record : e).toList(),
      source: 'replace id=${record.id}',
    );
  }

  Future<void> refreshFromRemote() {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(() => unawaited(refreshFromRemote()));
      return Future.value();
    }
    return _refreshFuture ??= _refreshFromRemoteImpl().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<void> _refreshFromRemoteImpl() async {
    final epoch = _epoch;
    if (!_ref.read(sessionProvider).isLoggedIn) {
      if (_isStale(epoch)) return;
      state = const HomeHistoryState(initialLoadDone: true);
      HomeHistoryMemoryCache.clear();
      return;
    }
    await _warmFromDisk();
    if (_isStale(epoch)) return;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) {
      _clearItemsForUnboundSession(epoch: epoch);
      return;
    }

    final cachedSnapshot = state.items.isNotEmpty
        ? _currentSnapshot()
        : await HomeHistoryStore.loadSnapshot(dn);
    if (_isStale(epoch)) return;
    if (cachedSnapshot.items.isNotEmpty && state.items.isEmpty) {
      _applyState(
        state.copyWith(
          items: cachedSnapshot.items,
          total: cachedSnapshot.total,
          highestPageLoaded: cachedSnapshot.highestPageLoaded,
        ),
        epoch: epoch,
      );
    }

    final page = await _ref.read(feedRepositoryProvider).tryLoadHistoryPage(page: 1);
    if (_isStale(epoch)) return;
    if (page == null) return;

    final remoteAsc = historyListToHomeAsc(page.listDesc);
    final mergedAsc = mergeRemoteHistoryAscWithPendingLocal(
      remoteAsc: remoteAsc,
      localItems: state.items,
    );

    final firstPageOnlyCached = cachedSnapshot.highestPageLoaded <= 1 &&
        historySnapshotsEqual(cachedSnapshot.items, remoteAsc);
    if (firstPageOnlyCached) {
      if (state.items.isEmpty && remoteAsc.isNotEmpty) {
        _applyState(
          state.copyWith(
            items: mergedAsc,
            total: page.total,
            highestPageLoaded: 1,
          ),
          epoch: epoch,
        );
      } else if (state.total != page.total || state.highestPageLoaded != 1) {
        _applyState(
          state.copyWith(total: page.total, highestPageLoaded: 1),
          epoch: epoch,
        );
      }
      return;
    }

    final next = state.copyWith(
      items: mergedAsc,
      total: page.total,
      highestPageLoaded: 1,
      loadingMore: false,
    );
    await HomeHistoryStore.saveSnapshot(
      dn,
      HomeHistoryCacheSnapshot(
        items: mergedAsc,
        total: page.total,
        highestPageLoaded: 1,
      ),
    );
    if (_isStale(epoch) || _deviceNo() != dn) {
      await HomeHistoryStore.clearAll();
      return;
    }
    _applyState(next, epoch: epoch);
    // 首页刷新可能变更近 7 日内容 → 失效预测 range
    if (_isStale(epoch)) return;
    if (_ref.read(sessionProvider).isLoggedIn) {
      _ref.read(predictionRangeHistoryProvider.notifier).scheduleInvalidation();
      unawaited(scheduleHomeWidgetSync(_ref, history: mergedAsc));
    }
  }

  Future<void> loadMoreHistory() async {
    await loadNextHistoryPage();
  }

  /// 加载下一页历史；成功返回 true（仅喂养列表分页，不驱动预测 range）。
  Future<bool> loadNextHistoryPage() async {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(() => unawaited(loadNextHistoryPage()));
      return false;
    }
    if (_loadPageInFlight != null) {
      return _loadPageInFlight!;
    }
    return _loadPageInFlight = _loadNextHistoryPageImpl().whenComplete(() {
      _loadPageInFlight = null;
    });
  }

  Future<bool> _loadNextHistoryPageImpl() async {
    final epoch = _epoch;
    if (!state.hasMore || state.loadingMore) return false;
    if (!_ref.read(sessionProvider).isLoggedIn) return false;
    if (isLoadMoreCircuitOpen) return false;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return false;

    final nextPage = state.highestPageLoaded + 1;
    state = state.copyWith(loadingMore: true);

    final page = await _ref.read(feedRepositoryProvider).tryLoadHistoryPage(page: nextPage);
    if (_isStale(epoch)) return false;
    if (page == null) {
      state = state.copyWith(loadingMore: false);
      _consecutiveLoadMoreFailures += 1;
      return false;
    }

    _consecutiveLoadMoreFailures = 0;
    final olderAsc = historyListToHomeAsc(page.listDesc);
    final existingIds = state.items.map((e) => e.id).toSet();
    final newOnes = olderAsc.where((e) => !existingIds.contains(e.id)).toList();
    final merged = [...newOnes, ...state.items];

    final next = state.copyWith(
      items: merged,
      total: page.total,
      highestPageLoaded: nextPage,
      loadingMore: false,
    );
    _applyState(next, epoch: epoch);
    if (_isStale(epoch)) return false;
    await HomeHistoryStore.saveSnapshot(
      dn,
      HomeHistoryCacheSnapshot(
        items: merged,
        total: page.total,
        highestPageLoaded: nextPage,
      ),
    );
    if (_isStale(epoch) || _deviceNo() != dn) {
      await HomeHistoryStore.clearAll();
      return false;
    }
    // 更旧分页不进入 7 日 range，无需同步小组件预测
    return true;
  }

  Future<void> bootstrap() async {
    final epoch = _epoch;
    try {
      if (!_ref.read(sessionProvider).isLoggedIn) {
        HomeHistoryMemoryCache.clear();
        state = const HomeHistoryState(initialLoadDone: true);
        return;
      }
      await loadFromDisk();
      if (_isStale(epoch)) return;
      await refreshFromRemote();
    } finally {
      if (!_isStale(epoch)) {
        state = state.copyWith(initialLoadDone: true);
      }
    }
  }
}

HomeHistoryState _homeHistoryInitialState(Ref ref) {
  if (!ref.read(sessionProvider).isLoggedIn) {
    return const HomeHistoryState();
  }
  final dn = ref.read(deviceNoNotifierProvider).asData?.value;
  final mem = HomeHistoryMemoryCache.peek(dn);
  if (mem.isEmpty) return const HomeHistoryState();
  return HomeHistoryState(
    items: mem,
    highestPageLoaded: 1,
  );
}

final homeHistoryProvider =
    StateNotifierProvider<HomeHistoryNotifier, HomeHistoryState>((ref) {
  return HomeHistoryNotifier(ref, _homeHistoryInitialState(ref));
});
