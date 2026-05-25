import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/history_list_page.dart';
import '../data/history_mapper.dart';
import '../data/home_history_store.dart';
import '../data/home_history_memory_cache.dart';
import '../data/models.dart';
import 'device_no_notifier.dart';
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
    if (state.items.isNotEmpty) {
      HomeHistoryLog.d(
        'provider created with memory cache count=${state.items.length}',
      );
    } else {
      HomeHistoryLog.d('provider created, warmFromDisk scheduled');
    }
    unawaited(_warmFromDisk());
  }

  final Ref _ref;
  Future<void>? _warmFuture;
  var _flyAnimationFrozen = false;
  final List<void Function()> _queuedWhileFlyFrozen = [];

  /// 飞行动画期间冻结列表变更，结束后再依次应用队列。
  void setFlyAnimationFrozen(bool frozen) {
    if (_flyAnimationFrozen == frozen) return;
    _flyAnimationFrozen = frozen;
    HomeHistoryLog.d('flyAnimationFrozen=$frozen queued=${_queuedWhileFlyFrozen.length}');
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

  void _applyState(
    HomeHistoryState next, {
    required String source,
  }) {
    final prev = state.items.length;
    state = next;
    HomeHistoryMemoryCache.update(_deviceNo(), next.items);
    HomeHistoryLog.d(
      'state update source=$source count=${next.items.length} prev=$prev '
      'total=${next.total} pages=${next.highestPageLoaded} '
      'initialLoadDone=${next.initialLoadDone}',
    );
  }

  void _applyItems(
    List<HistoryRecord> items, {
    int? total,
    int? highestPageLoaded,
    required String source,
  }) {
    _applyState(
      state.copyWith(
        items: items,
        total: total,
        highestPageLoaded: highestPageLoaded,
      ),
      source: source,
    );
  }

  Future<void> _warmFromDisk() {
    return _warmFuture ??= _loadWarmFromDisk();
  }

  Future<void> _loadWarmFromDisk() async {
    if (state.items.isNotEmpty) {
      HomeHistoryLog.d('warmFromDisk skip: memory already has ${state.items.length}');
      return;
    }
    HomeHistoryLog.d('warmFromDisk start');
    if (!_ref.read(sessionProvider).isLoggedIn) {
      HomeHistoryLog.d('warmFromDisk skip: not logged in');
      return;
    }
    var dn = _ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) {
      HomeHistoryLog.d('warmFromDisk deviceNo empty, refreshing…');
      await _ref.read(deviceNoNotifierProvider.notifier).refresh();
      dn = _ref.read(deviceNoNotifierProvider).asData?.value;
    }
    if (dn == null || dn.isEmpty) {
      HomeHistoryLog.d('warmFromDisk skip: deviceNo still empty');
      return;
    }
    final cached = await HomeHistoryStore.loadSnapshot(dn);
    if (cached.items.isEmpty) {
      HomeHistoryLog.d('warmFromDisk: cache empty (deviceNo=$dn)');
      return;
    }
    _applyState(
      state.copyWith(
        items: cached.items,
        total: cached.total,
        highestPageLoaded: cached.highestPageLoaded,
      ),
      source: 'warmFromDisk',
    );
  }

  String? _deviceNo() => _ref.read(deviceNoNotifierProvider).asData?.value;

  Future<void> loadFromDisk() async {
    if (state.items.isNotEmpty) {
      HomeHistoryLog.d('loadFromDisk skip: memory already has ${state.items.length}');
      return;
    }
    HomeHistoryLog.d('loadFromDisk start');
    await _warmFromDisk();
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
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return;
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    final snapshot = _currentSnapshot();
    HomeHistoryLog.d(
      'persistToDisk count=${snapshot.items.length} total=${snapshot.total}',
    );
    unawaited(HomeHistoryStore.saveSnapshot(dn, snapshot));
  }

  void setItems(List<HistoryRecord> items, {bool persist = true, String source = 'setItems'}) {
    if (_enqueueIfFrozen(() => setItems(items, persist: persist, source: source))) {
      return;
    }
    _setItemsNow(items, persist: persist, source: source);
  }

  void _setItemsNow(List<HistoryRecord> items, {bool persist = true, required String source}) {
    _applyItems(items, source: source);
    if (persist) unawaited(persistToDisk());
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
    _setItemsNow(
      [...state.items, record],
      source: 'insertOptimistic id=${record.id}',
    );
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

  Future<void> refreshFromRemote() async {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(() => unawaited(refreshFromRemote()));
      return;
    }
    HomeHistoryLog.d('refreshFromRemote start memory=${state.items.length}');
    if (!_ref.read(sessionProvider).isLoggedIn) {
      HomeHistoryLog.d('refreshFromRemote skip: not logged in');
      state = const HomeHistoryState(initialLoadDone: true);
      HomeHistoryMemoryCache.clear();
      return;
    }
    await _warmFromDisk();
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) {
      HomeHistoryLog.d('refreshFromRemote skip: deviceNo empty');
      return;
    }

    final cachedSnapshot = state.items.isNotEmpty
        ? _currentSnapshot()
        : await HomeHistoryStore.loadSnapshot(dn);
    HomeHistoryLog.d('refreshFromRemote cache read count=${cachedSnapshot.items.length}');
    if (cachedSnapshot.items.isNotEmpty && state.items.isEmpty) {
      _applyState(
        state.copyWith(
          items: cachedSnapshot.items,
          total: cachedSnapshot.total,
          highestPageLoaded: cachedSnapshot.highestPageLoaded,
        ),
        source: 'refreshFromRemote(cache)',
      );
    }

    final sw = Stopwatch()..start();
    final page = await _ref.read(feedRepositoryProvider).tryLoadHistoryPage(page: 1);
    sw.stop();
    if (page == null) {
      HomeHistoryLog.d(
        'refreshFromRemote api returned null (${sw.elapsedMilliseconds}ms), keep memory=${state.items.length}',
      );
      return;
    }

    final remoteAsc = historyListToHomeAsc(page.listDesc);
    HomeHistoryLog.d(
      'refreshFromRemote api ok count=${remoteAsc.length} total=${page.total} '
      'elapsed=${sw.elapsedMilliseconds}ms',
    );

    final firstPageOnlyCached = cachedSnapshot.highestPageLoaded <= 1 &&
        historySnapshotsEqual(cachedSnapshot.items, remoteAsc);
    if (firstPageOnlyCached) {
      HomeHistoryLog.d('refreshFromRemote skip write: same as cache page1');
      if (state.items.isEmpty && remoteAsc.isNotEmpty) {
        _applyState(
          state.copyWith(
            items: remoteAsc,
            total: page.total,
            highestPageLoaded: 1,
          ),
          source: 'refreshFromRemote(syncMemory)',
        );
      } else if (state.total != page.total || state.highestPageLoaded != 1) {
        _applyState(
          state.copyWith(total: page.total, highestPageLoaded: 1),
          source: 'refreshFromRemote(syncMeta)',
        );
      }
      return;
    }

    final next = state.copyWith(
      items: remoteAsc,
      total: page.total,
      highestPageLoaded: 1,
      loadingMore: false,
    );
    await HomeHistoryStore.saveSnapshot(
      dn,
      HomeHistoryCacheSnapshot(
        items: remoteAsc,
        total: page.total,
        highestPageLoaded: 1,
      ),
    );
    _applyState(next, source: 'refreshFromRemote(api)');
    HomeHistoryLog.d('refreshFromRemote saved disk count=${remoteAsc.length}');
  }

  Future<void> loadMoreHistory() async {
    if (_flyAnimationFrozen) {
      _enqueueIfFrozen(() => unawaited(loadMoreHistory()));
      return;
    }
    if (!state.hasMore || state.loadingMore) {
      HomeHistoryLog.d(
        'loadMoreHistory skip hasMore=${state.hasMore} loading=${state.loadingMore}',
      );
      return;
    }
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return;

    final nextPage = state.highestPageLoaded + 1;
    state = state.copyWith(loadingMore: true);
    HomeHistoryLog.d('loadMoreHistory start page=$nextPage');

    final sw = Stopwatch()..start();
    final page = await _ref.read(feedRepositoryProvider).tryLoadHistoryPage(page: nextPage);
    sw.stop();
    if (page == null) {
      HomeHistoryLog.d('loadMoreHistory failed elapsed=${sw.elapsedMilliseconds}ms');
      state = state.copyWith(loadingMore: false);
      return;
    }

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
    _applyState(next, source: 'loadMoreHistory page=$nextPage added=${newOnes.length}');
    await HomeHistoryStore.saveSnapshot(
      dn,
      HomeHistoryCacheSnapshot(
        items: merged,
        total: page.total,
        highestPageLoaded: nextPage,
      ),
    );
    HomeHistoryLog.d(
      'loadMoreHistory ok page=$nextPage added=${newOnes.length} total=${page.total} '
      'elapsed=${sw.elapsedMilliseconds}ms',
    );
  }

  Future<void> bootstrap() async {
    HomeHistoryLog.d('bootstrap start memory=${state.items.length}');
    try {
      if (!_ref.read(sessionProvider).isLoggedIn) {
        HomeHistoryLog.d('bootstrap skip: not logged in');
        HomeHistoryMemoryCache.clear();
        state = const HomeHistoryState(initialLoadDone: true);
        return;
      }
      await loadFromDisk();
      await refreshFromRemote();
    } finally {
      state = state.copyWith(initialLoadDone: true);
      HomeHistoryLog.d(
        'bootstrap done memory=${state.items.length} initialLoadDone=true',
      );
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
  HomeHistoryLog.d('initialState from memory cache count=${mem.length} deviceNo=$dn');
  return HomeHistoryState(
    items: mem,
    highestPageLoaded: 1,
  );
}

final homeHistoryProvider =
    StateNotifierProvider<HomeHistoryNotifier, HomeHistoryState>((ref) {
  return HomeHistoryNotifier(ref, _homeHistoryInitialState(ref));
});
