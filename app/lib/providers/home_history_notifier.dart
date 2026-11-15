import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/event_next_predictor.dart';
import '../data/history_list_page.dart';
import '../data/history_mapper.dart';
import '../data/home_history_store.dart';
import '../data/home_history_memory_cache.dart';
import '../data/models.dart';
import '../data/prediction_range_history.dart';
import '../home_widget/home_widget_sync.dart';
import '../data/smart_prediction_rows.dart';
import 'device_no_notifier.dart';
import 'event_catalog_notifier.dart';
import 'event_last_at_provider.dart';
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
    this.seeding = false,
    this.hasMoreOlder = true,
    this.seedTruncated = false,
  });

  final List<HistoryRecord> items;
  final bool initialLoadDone;
  final int total;
  /// 兼容旧快照；统一池 loadMore 不再依赖页码。
  final int highestPageLoaded;
  final bool loadingMore;
  /// 近 7 日 filter 种子进行中。
  final bool seeding;
  /// 时间游标是否还可能有更旧记录。
  final bool hasMoreOlder;
  /// 最近一次种子是否触顶 500。
  final bool seedTruncated;

  /// 喂养列表「还有更多」：统一池以 [hasMoreOlder] 为准。
  bool get hasMore => hasMoreOlder;

  HomeHistoryState copyWith({
    List<HistoryRecord>? items,
    bool? initialLoadDone,
    int? total,
    int? highestPageLoaded,
    bool? loadingMore,
    bool? seeding,
    bool? hasMoreOlder,
    bool? seedTruncated,
  }) {
    return HomeHistoryState(
      items: items ?? this.items,
      initialLoadDone: initialLoadDone ?? this.initialLoadDone,
      total: total ?? this.total,
      highestPageLoaded: highestPageLoaded ?? this.highestPageLoaded,
      loadingMore: loadingMore ?? this.loadingMore,
      seeding: seeding ?? this.seeding,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      seedTruncated: seedTruncated ?? this.seedTruncated,
    );
  }
}

/// 记录发生时刻 unix 秒（startTime，缺省 createdAt）。
int? historyRecordStartUnixSeconds(HistoryRecord r) {
  final t = occurrenceInstant(r, includeActive: true);
  if (t == null) return null;
  return historyDateTimeToUnixSeconds(t);
}

void _sortHistoryAscByStart(List<HistoryRecord> items) {
  items.sort((a, b) {
    final sa = historyRecordStartUnixSeconds(a) ?? 0;
    final sb = historyRecordStartUnixSeconds(b) ?? 0;
    if (sa != sb) return sa.compareTo(sb);
    return a.id.compareTo(b.id);
  });
}

class HomeHistoryNotifier extends StateNotifier<HomeHistoryState> {
  HomeHistoryNotifier(this._ref, HomeHistoryState initialState)
      : super(initialState) {
    unawaited(_warmFromDisk());
  }

  final Ref _ref;
  Future<void>? _warmFuture;
  Future<bool>? _loadPageInFlight;
  Future<bool>? _refreshFuture;
  Future<bool>? _seedInFlight;
  Future<bool>? _rollingInFlight;
  var _flyAnimationFrozen = false;
  var _consecutiveLoadMoreFailures = 0;
  var _consecutiveSeedFailures = 0;
  /// 本会话是否已成功跑过一次远端 7 日种子（磁盘 hydrate 不算）。
  var _remoteSeedSucceeded = false;
  final List<void Function()> _queuedWhileFlyFrozen = [];

  static const _kMaxSeedFailures = 3;

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
    bool? hasMoreOlder,
    required int epoch,
  }) {
    _applyState(
      state.copyWith(
        items: items,
        total: total,
        highestPageLoaded: highestPageLoaded,
        hasMoreOlder: hasMoreOlder,
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
        hasMoreOlder: cached.hasMoreOlder,
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
    _seedInFlight = null;
    _flyAnimationFrozen = false;
    _deviceChangeBootstrapFuture = null;
    _bootstrapInFlightForDeviceNo = null;
    _consecutiveSeedFailures = 0;
    _remoteSeedSucceeded = false;
    HomeHistoryMemoryCache.clear();
    state = const HomeHistoryState(initialLoadDone: true);
  }

  Future<void>? _deviceChangeBootstrapFuture;
  String? _bootstrapInFlightForDeviceNo;

  /// 宝宝 ID 变更：作废 in-flight、清内存缓存，再 bootstrap 拉取新宝宝历史。
  Future<void> onDeviceNoChanged() {
    if (!_ref.read(sessionProvider).isLoggedIn) {
      return Future.value();
    }
    final dn = _deviceNo()?.trim();
    if (dn == null || dn.isEmpty) {
      return Future.value();
    }
    if (_deviceChangeBootstrapFuture != null &&
        _bootstrapInFlightForDeviceNo == dn) {
      return _deviceChangeBootstrapFuture!;
    }

    _bootstrapInFlightForDeviceNo = dn;
    _epoch++;
    _queuedWhileFlyFrozen.clear();
    _warmFuture = null;
    _refreshFuture = null;
    _loadPageInFlight = null;
    _seedInFlight = null;
    _consecutiveLoadMoreFailures = 0;
    _consecutiveSeedFailures = 0;
    _remoteSeedSucceeded = false;
    HomeHistoryMemoryCache.clear();
    state = const HomeHistoryState();

    _deviceChangeBootstrapFuture = bootstrap().whenComplete(() {
      if (_bootstrapInFlightForDeviceNo == dn) {
        _bootstrapInFlightForDeviceNo = null;
      }
      _deviceChangeBootstrapFuture = null;
    });
    return _deviceChangeBootstrapFuture!;
  }

  HomeHistoryCacheSnapshot _currentSnapshot() {
    return HomeHistoryCacheSnapshot(
      items: state.items,
      total: state.total > 0 ? state.total : state.items.length,
      highestPageLoaded: state.highestPageLoaded > 0
          ? state.highestPageLoaded
          : (state.items.isEmpty ? 0 : 1),
      hasMoreOlder: state.hasMoreOlder,
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
      // 统一池变更 → 推小组件；预测只读本池
      unawaited(scheduleHomeWidgetSync(_ref));
      final catalog = _ref.read(eventCatalogProvider).items;
      scheduleEventLastAtObserveFromHistory(_ref, state.items, catalog);
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
    // 删除前快照，供事件最近发生 tip 失效
    HistoryRecord? removed;
    for (final e in state.items) {
      if (e.id == id) {
        removed = e;
        break;
      }
    }
    setItems(
      state.items.where((e) => e.id != id).toList(),
      source: 'wsRemove id=$id',
    );
    if (removed != null && !isPredictionRecallSeedRecord(removed)) {
      final catalog = _ref.read(eventCatalogProvider).items;
      unawaited(
        invalidateEventLastAtForRemovedRecord(
          _ref,
          removed: removed,
          catalog: catalog,
          visibleAfter: state.items,
        ),
      );
    }
  }

  void replaceRecord(HistoryRecord record) {
    if (_enqueueIfFrozen(() => replaceRecord(record))) return;
    setItems(
      state.items.map((e) => e.id == record.id ? record : e).toList(),
      source: 'replace id=${record.id}',
    );
  }

  /// 远端刷新：一次近 7 日 filter 种子；成功 true。
  /// [preserveLoadedDepth] 保留窗起点之前的更旧行（默认种子均保留）。
  /// 冷启 / ColdStart 用；resume 与预测下拉请用 [refreshRollingWindow]。
  Future<bool> refreshFromRemote({bool preserveLoadedDepth = true}) {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(
        () => unawaited(
          refreshFromRemote(preserveLoadedDepth: preserveLoadedDepth),
        ),
      );
      return Future.value(true);
    }
    final existing = _refreshFuture;
    if (existing != null) return existing;
    return _refreshFuture = seedSevenDayHistory(
      force: true,
      preserveOlderOutsideWindow: preserveLoadedDepth,
    ).whenComplete(() {
      _refreshFuture = null;
    });
  }

  /// resume / 预测下拉：滚动 24h filter 合并；保留窗外更旧本地行。
  Future<bool> refreshRollingWindow({
    bool preserveOlderOutsideWindow = true,
  }) {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(
        () => unawaited(
          refreshRollingWindow(
            preserveOlderOutsideWindow: preserveOlderOutsideWindow,
          ),
        ),
      );
      return Future.value(true);
    }
    final existing = _rollingInFlight;
    if (existing != null) return existing;
    return _rollingInFlight = _refreshRollingWindowImpl(
      preserveOlderOutsideWindow: preserveOlderOutsideWindow,
    ).whenComplete(() {
      _rollingInFlight = null;
    });
  }

  Future<bool> _refreshRollingWindowImpl({
    required bool preserveOlderOutsideWindow,
  }) async {
    final epoch = _epoch;
    if (!_ref.read(sessionProvider).isLoggedIn) {
      return false;
    }
    await _warmFromDisk();
    if (_isStale(epoch)) return true;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      if (_isStale(epoch)) return true;
    }
    final resolvedDn = _deviceNo();
    if (resolvedDn == null || resolvedDn.isEmpty) {
      return false;
    }

    final windowAsc = await fetchPredictionRolling24hHistory(
      _ref.read(feedRepositoryProvider),
    );
    if (_isStale(epoch)) return true;
    if (windowAsc == null) {
      AppDebugLog.homeWidget('history rolling24h merge fail');
      return false;
    }

    final bounds = predictionRolling24hUnixBounds();
    final windowStart = bounds.$1;
    final windowIds = windowAsc.map((e) => e.id).toSet();
    final olderKept = <HistoryRecord>[];
    if (preserveOlderOutsideWindow) {
      for (final e in state.items) {
        if (windowIds.contains(e.id) || isPendingHistoryId(e.id)) continue;
        final sec = historyRecordStartUnixSeconds(e);
        if (sec != null && sec < windowStart) {
          olderKept.add(e);
        }
      }
    }

    final combined = <HistoryRecord>[...olderKept, ...windowAsc];
    _sortHistoryAscByStart(combined);
    final mergedAsc = mergeRemoteHistoryAscWithPendingLocal(
      remoteAsc: combined,
      localItems: state.items,
    );
    _sortHistoryAscByStart(mergedAsc);

    final next = state.copyWith(
      items: mergedAsc,
      total: mergedAsc.length,
      highestPageLoaded: mergedAsc.isEmpty ? 0 : state.highestPageLoaded,
      loadingMore: false,
      seeding: false,
      hasMoreOlder: state.hasMoreOlder || olderKept.isNotEmpty,
      initialLoadDone: true,
    );
    await HomeHistoryStore.saveSnapshot(
      resolvedDn,
      HomeHistoryCacheSnapshot(
        items: mergedAsc,
        total: mergedAsc.length,
        highestPageLoaded: next.highestPageLoaded,
        hasMoreOlder: next.hasMoreOlder,
      ),
    );
    if (_isStale(epoch) || _deviceNo() != resolvedDn) {
      await HomeHistoryStore.clearAll();
      return true;
    }
    _applyState(next, epoch: epoch);
    if (_isStale(epoch)) return true;
    if (_ref.read(sessionProvider).isLoggedIn) {
      unawaited(scheduleHomeWidgetSync(_ref));
      final catalog = _ref.read(eventCatalogProvider).items;
      scheduleEventLastAtObserveFromHistory(_ref, mergedAsc, catalog);
    }
    return true;
  }

  /// 近 7 日一次 filter 种子（single-flight）；触顶截断不补页。
  Future<bool> seedSevenDayHistory({
    bool force = false,
    bool preserveOlderOutsideWindow = true,
  }) {
    final existing = _seedInFlight;
    if (existing != null) {
      if (!force) return existing;
      return existing.then((_) => seedSevenDayHistory(
            force: true,
            preserveOlderOutsideWindow: preserveOlderOutsideWindow,
          ));
    }
    return _seedInFlight = _seedSevenDayImpl(
      force: force,
      preserveOlderOutsideWindow: preserveOlderOutsideWindow,
    ).whenComplete(() {
      _seedInFlight = null;
    });
  }

  Future<bool> _seedSevenDayImpl({
    required bool force,
    required bool preserveOlderOutsideWindow,
  }) async {
    final epoch = _epoch;
    if (!_ref.read(sessionProvider).isLoggedIn) {
      if (_isStale(epoch)) return true;
      state = const HomeHistoryState(initialLoadDone: true);
      HomeHistoryMemoryCache.clear();
      return false;
    }
    await _warmFromDisk();
    if (_isStale(epoch)) return true;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) {
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      if (_isStale(epoch)) return true;
    }
    final resolvedDn = _deviceNo();
    if (resolvedDn == null || resolvedDn.isEmpty) {
      _clearItemsForUnboundSession(epoch: epoch);
      return false;
    }

    if (!force && _remoteSeedSucceeded) {
      return true;
    }
    if (_consecutiveSeedFailures >= _kMaxSeedFailures && !force) {
      AppDebugLog.homeWidget('history seed skipped circuit open');
      return false;
    }

    state = state.copyWith(seeding: true);
    final windowAsc = await fetchPredictionSevenDayHistory(
      _ref.read(feedRepositoryProvider),
    );
    if (_isStale(epoch)) return true;
    if (windowAsc == null) {
      _consecutiveSeedFailures += 1;
      state = state.copyWith(seeding: false);
      return false;
    }
    _consecutiveSeedFailures = 0;
    _remoteSeedSucceeded = true;

    final bounds = predictionSevenDayUnixBounds();
    final windowStart = bounds.$1;
    final truncated = windowAsc.length >= kHistoryFilterMaxLimit;

    final windowIds = windowAsc.map((e) => e.id).toSet();
    final olderKept = <HistoryRecord>[];
    if (preserveOlderOutsideWindow) {
      for (final e in state.items) {
        if (windowIds.contains(e.id) || isPendingHistoryId(e.id)) continue;
        final sec = historyRecordStartUnixSeconds(e);
        if (sec != null && sec < windowStart) {
          olderKept.add(e);
        }
      }
    }

    final combined = <HistoryRecord>[...olderKept, ...windowAsc];
    _sortHistoryAscByStart(combined);
    final mergedAsc = mergeRemoteHistoryAscWithPendingLocal(
      remoteAsc: combined,
      localItems: state.items,
    );
    _sortHistoryAscByStart(mergedAsc);

    final next = state.copyWith(
      items: mergedAsc,
      total: mergedAsc.length,
      highestPageLoaded: mergedAsc.isEmpty ? 0 : 1,
      loadingMore: false,
      seeding: false,
      hasMoreOlder: true,
      seedTruncated: truncated,
      initialLoadDone: true,
    );
    await HomeHistoryStore.saveSnapshot(resolvedDn, HomeHistoryCacheSnapshot(
      items: mergedAsc,
      total: mergedAsc.length,
      highestPageLoaded: next.highestPageLoaded,
      hasMoreOlder: true,
    ));
    if (_isStale(epoch) || _deviceNo() != resolvedDn) {
      await HomeHistoryStore.clearAll();
      return true;
    }
    _applyState(next, epoch: epoch);
    if (_isStale(epoch)) return true;
    if (_ref.read(sessionProvider).isLoggedIn) {
      unawaited(scheduleHomeWidgetSync(_ref));
      final catalog = _ref.read(eventCatalogProvider).items;
      scheduleEventLastAtObserveFromHistory(_ref, mergedAsc, catalog);
    }
    return true;
  }

  Future<void> loadMoreHistory() async {
    await loadNextHistoryPage();
  }

  /// 时间游标加载更旧历史；成功返回 true。
  Future<bool> loadNextHistoryPage() async {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(() => unawaited(loadNextHistoryPage()));
      return false;
    }
    if (_loadPageInFlight != null) {
      return _loadPageInFlight!;
    }
    return _loadPageInFlight = _loadOlderByTimeCursorImpl().whenComplete(() {
      _loadPageInFlight = null;
    });
  }

  Future<bool> _loadOlderByTimeCursorImpl() async {
    final epoch = _epoch;
    if (!state.hasMoreOlder || state.loadingMore) return false;
    if (!_ref.read(sessionProvider).isLoggedIn) return false;
    if (isLoadMoreCircuitOpen) return false;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return false;

    // 游标：池内最旧 startTime−1；空池则用 7 日窗起点−1
    int? oldestSec;
    for (final e in state.items) {
      final sec = historyRecordStartUnixSeconds(e);
      if (sec == null) continue;
      if (oldestSec == null || sec < oldestSec) oldestSec = sec;
    }
    oldestSec ??= predictionSevenDayUnixBounds().$1;
    final endTime = oldestSec - 1;
    if (endTime < 1) {
      state = state.copyWith(hasMoreOlder: false);
      return true;
    }

    state = state.copyWith(loadingMore: true);
    final listDesc = await _ref.read(feedRepositoryProvider).tryLoadHistoryFilter(
          endTime: endTime,
          limit: kHomeHistoryPageSize,
        );
    if (_isStale(epoch)) return false;
    if (listDesc == null) {
      state = state.copyWith(loadingMore: false);
      _consecutiveLoadMoreFailures += 1;
      return false;
    }

    _consecutiveLoadMoreFailures = 0;
    if (listDesc.isEmpty) {
      final next = state.copyWith(
        loadingMore: false,
        hasMoreOlder: false,
      );
      _applyState(next, epoch: epoch);
      unawaited(persistToDisk());
      return true;
    }

    final olderAsc = historyListToHomeAsc(listDesc);
    final existingIds = state.items.map((e) => e.id).toSet();
    final newOnes =
        olderAsc.where((e) => !existingIds.contains(e.id)).toList();
    final merged = [...newOnes, ...state.items];
    _sortHistoryAscByStart(merged);

    final next = state.copyWith(
      items: merged,
      total: merged.length,
      loadingMore: false,
      hasMoreOlder: newOnes.isNotEmpty,
      highestPageLoaded: state.highestPageLoaded + 1,
    );
    _applyState(next, epoch: epoch);
    if (_isStale(epoch)) return false;
    await HomeHistoryStore.saveSnapshot(
      dn,
      HomeHistoryCacheSnapshot(
        items: merged,
        total: merged.length,
        highestPageLoaded: next.highestPageLoaded,
        hasMoreOlder: next.hasMoreOlder,
      ),
    );
    if (_isStale(epoch) || _deviceNo() != dn) {
      await HomeHistoryStore.clearAll();
      return false;
    }
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
      // 主壳/切号：一次 7 日种子，保留窗外更旧
      await seedSevenDayHistory(force: true, preserveOlderOutsideWindow: true);
    } finally {
      if (!_isStale(epoch)) {
        state = state.copyWith(initialLoadDone: true, seeding: false);
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
    hasMoreOlder: true,
  );
}

final homeHistoryProvider =
    StateNotifierProvider<HomeHistoryNotifier, HomeHistoryState>((ref) {
  final notifier = HomeHistoryNotifier(ref, _homeHistoryInitialState(ref));
  ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
    if (!ref.read(sessionProvider).isLoggedIn) return;
    final nextDn = next.asData?.value?.trim();
    if (nextDn == null || nextDn.isEmpty) return;
    final prevDn = prev?.asData?.value?.trim();
    if (prevDn == nextDn) return;
    unawaited(notifier.onDeviceNoChanged());
  });
  return notifier;
});
