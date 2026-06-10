import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_catalog_state.dart';
import '../data/event_catalog_store.dart';
import '../data/event_catalog_sync.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

class EventCatalogNotifier extends StateNotifier<EventCatalogState> {
  EventCatalogNotifier(this._ref) : super(const EventCatalogState()) {
    unawaited(_warmFromDisk());
  }

  static const _logoDownloadConcurrency = 6;

  final Ref _ref;
  Future<void>? _warmFuture;
  Future<void>? _refreshFuture;
  Future<void>? _logoDownloadFuture;
  Timer? _saveDebounce;

  List<EventDefinition> get items => state.items;

  Future<void> _warmFromDisk() {
    return _warmFuture ??= _loadWarmFromDisk();
  }

  Future<void> _loadWarmFromDisk() async {
    final cached = await EventCatalogStore.loadFromDisk();
    if (cached.isNotEmpty && state.items.isEmpty) {
      state = state.copyWith(items: cached);
      _debugLog('warmFromDisk: ${cached.length} items');
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[EventCatalog] $message');
  }

  EventDefinition? lookupByEventId(Object? eventId) {
    if (eventId == null) return null;
    final key = eventId.toString().trim();
    if (key.isEmpty) return null;
    for (final e in state.items) {
      if (historyEventIdsMatch(eventId, e.id) || e.id == key) return e;
    }
    return null;
  }

  EventDefinition? lookupByName(String eventName) {
    final name = eventName.trim();
    if (name.isEmpty) return null;
    EventDefinition? match;
    for (final e in state.items) {
      if (e.name.trim() == name) {
        if (match != null) return null;
        match = e;
      }
    }
    return match;
  }

  Future<void> loadFromDisk() async {
    await _warmFromDisk();
    final cached = await EventCatalogStore.loadFromDisk();
    if (cached.isEmpty) {
      if (state.items.isNotEmpty) return;
      return;
    }
    state = state.copyWith(items: cached);
  }

  Future<void> refreshFromRemote() {
    return _refreshFuture ??= _refreshFromRemoteImpl(markRemoteAttempt: true).whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<void> _refreshFromRemoteImpl({required bool markRemoteAttempt}) async {
    state = state.copyWith(isRefreshing: true);
    try {
      final loggedIn = _ref.read(sessionProvider).isLoggedIn;
      await _warmFromDisk();
      if (state.items.isEmpty) {
        await loadFromDisk();
      }
      final dn = loggedIn ? _ref.read(deviceNoNotifierProvider).asData?.value : null;

      final sync = EventCatalogSync(_ref.read(authorizedApiClientProvider));
      final updated = await sync.refreshAndPersist(
        deviceNo: dn,
        withAuthorization: loggedIn,
      );
      _applyRefreshResult(updated, dn);
      if (updated != null && updated.isNotEmpty) {
        unawaited(_downloadLogosInBackground(updated));
      }
    } finally {
      state = state.copyWith(
        isRefreshing: false,
        remoteLoadAttempted: markRemoteAttempt || state.remoteLoadAttempted,
      );
    }
  }

  void patchEventLocalLogoPath(String eventId, String path) {
    final idx = state.items.indexWhere((e) => e.id == eventId);
    if (idx < 0) return;
    final next = [...state.items];
    next[idx] = next[idx].copyWith(localLogoPath: path);
    state = state.copyWith(items: next);
  }

  void _scheduleSaveToDisk() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(EventCatalogStore.saveToDisk(state.items));
    });
  }

  Future<void> _downloadLogosInBackground(List<EventDefinition> base) {
    return _logoDownloadFuture ??= _downloadLogosImpl(base).whenComplete(() {
      _logoDownloadFuture = null;
    });
  }

  Future<void> _downloadLogosImpl(List<EventDefinition> base) async {
    if (base.isEmpty) return;
    try {
      final local = await EventCatalogStore.loadFromDisk();
      final prevById = {for (final e in local) e.id: e};
      var index = 0;

      Future<void> worker() async {
        while (true) {
          final i = index++;
          if (i >= base.length) return;
          final event = base[i];
          final resolved =
              await EventCatalogStore.downloadLogoIfNeeded(event, prevById);
          prevById[event.id] = resolved;
          final path = resolved.localLogoPath;
          if (path != null && path != event.localLogoPath) {
            patchEventLocalLogoPath(event.id, path);
            _scheduleSaveToDisk();
          }
        }
      }

      final workerCount = base.length < _logoDownloadConcurrency
          ? base.length
          : _logoDownloadConcurrency;
      if (workerCount > 0) {
        await Future.wait(List.generate(workerCount, (_) => worker()));
      }

      _saveDebounce?.cancel();
      await EventCatalogStore.saveToDisk(state.items);
      final keepPaths =
          state.items.map((e) => e.localLogoPath).whereType<String>().toSet();
      await EventCatalogStore.pruneLogoFiles(keepPaths);
      _debugLog('logos persisted: ${state.items.length} items');
    } catch (_) {}
  }

  void _applyRefreshResult(List<EventDefinition>? updated, String? deviceNo) {
    if (updated == null) return;
    if (updated.isEmpty && state.items.isNotEmpty) {
      _debugLog('refresh skipped empty remote (keeping ${state.items.length} in memory)');
      return;
    }
    if (updated.isNotEmpty) {
      state = state.copyWith(items: updated);
      _debugLog('refresh: ${updated.length} items (deviceNo=${deviceNo ?? "none"})');
    }
  }

  /// 先读盘再异步刷新；冷启动时若首次失败则短暂延迟后重试。
  Future<void> bootstrap({int maxAttempts = 3}) async {
    await _warmFromDisk();
    await loadFromDisk();
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (state.items.isNotEmpty && attempt > 1) break;
      await _refreshFromRemoteImpl(markRemoteAttempt: attempt == maxAttempts);
      if (state.items.isNotEmpty) break;
      if (attempt < maxAttempts) {
        _debugLog('bootstrap retry $attempt/$maxAttempts (catalog still empty)');
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    if (state.items.isEmpty) {
      _debugLog('bootstrap finished with empty catalog');
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}

final eventCatalogProvider =
    StateNotifierProvider<EventCatalogNotifier, EventCatalogState>((ref) {
  return EventCatalogNotifier(ref);
});
