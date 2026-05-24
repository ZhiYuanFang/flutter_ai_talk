import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final List<HistoryRecord> items;
  final bool initialLoadDone;

  HomeHistoryState copyWith({
    List<HistoryRecord>? items,
    bool? initialLoadDone,
  }) {
    return HomeHistoryState(
      items: items ?? this.items,
      initialLoadDone: initialLoadDone ?? this.initialLoadDone,
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

  void _applyItems(List<HistoryRecord> items, String source) {
    final prev = state.items.length;
    state = state.copyWith(items: items);
    HomeHistoryMemoryCache.update(_deviceNo(), items);
    HomeHistoryLog.d(
      'state update source=$source count=${items.length} prev=$prev '
      'initialLoadDone=${state.initialLoadDone}',
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
    final cached = await HomeHistoryStore.load(dn);
    if (cached.isEmpty) {
      HomeHistoryLog.d('warmFromDisk: cache empty (deviceNo=$dn)');
      return;
    }
    _applyItems(cached, 'warmFromDisk');
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

  Future<void> persistToDisk() async {
    final dn = _deviceNo();
    if (dn == null || dn.isEmpty) return;
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    HomeHistoryLog.d('persistToDisk count=${state.items.length}');
    unawaited(HomeHistoryStore.save(dn, state.items));
  }

  void setItems(List<HistoryRecord> items, {bool persist = true, String source = 'setItems'}) {
    _applyItems(items, source);
    if (persist) unawaited(persistToDisk());
  }

  void upsertRecord(HistoryRecord record) {
    final next = [...state.items.where((e) => e.id != record.id), record];
    setItems(next, source: 'wsUpsert id=${record.id}');
  }

  void removeRecord(String id) {
    setItems(
      state.items.where((e) => e.id != id).toList(),
      source: 'wsRemove id=$id',
    );
  }

  void replaceRecord(HistoryRecord record) {
    setItems(
      state.items.map((e) => e.id == record.id ? record : e).toList(),
      source: 'replace id=${record.id}',
    );
  }

  Future<void> refreshFromRemote() async {
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

    final cached = state.items.isNotEmpty
        ? state.items
        : await HomeHistoryStore.load(dn);
    HomeHistoryLog.d('refreshFromRemote cache read count=${cached.length}');
    if (cached.isNotEmpty && state.items.isEmpty) {
      _applyItems(cached, 'refreshFromRemote(cache)');
    }

    final sw = Stopwatch()..start();
    final remoteDesc = await _ref.read(feedRepositoryProvider).tryLoadHistory();
    sw.stop();
    if (remoteDesc == null) {
      HomeHistoryLog.d(
        'refreshFromRemote api returned null (${sw.elapsedMilliseconds}ms), keep memory=${state.items.length}',
      );
      return;
    }

    final remoteAsc = historyListToHomeAsc(remoteDesc);
    HomeHistoryLog.d(
      'refreshFromRemote api ok count=${remoteAsc.length} elapsed=${sw.elapsedMilliseconds}ms',
    );

    if (historySnapshotsEqual(cached, remoteAsc)) {
      HomeHistoryLog.d('refreshFromRemote skip write: same as cache');
      if (state.items.isEmpty && remoteAsc.isNotEmpty) {
        _applyItems(remoteAsc, 'refreshFromRemote(syncMemory)');
      }
      return;
    }

    await HomeHistoryStore.save(dn, remoteAsc);
    _applyItems(remoteAsc, 'refreshFromRemote(api)');
    HomeHistoryLog.d('refreshFromRemote saved disk count=${remoteAsc.length}');
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
  return HomeHistoryState(items: mem);
}

final homeHistoryProvider =
    StateNotifierProvider<HomeHistoryNotifier, HomeHistoryState>((ref) {
  return HomeHistoryNotifier(ref, _homeHistoryInitialState(ref));
});
