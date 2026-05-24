import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_catalog_store.dart';
import '../data/event_catalog_sync.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

class EventCatalogNotifier extends StateNotifier<List<EventDefinition>> {
  EventCatalogNotifier(this._ref) : super(const []) {
    unawaited(_warmFromDisk());
  }

  final Ref _ref;
  Future<void>? _warmFuture;

  Future<void> _warmFromDisk() {
    return _warmFuture ??= _loadWarmFromDisk();
  }

  Future<void> _loadWarmFromDisk() async {
    final cached = await EventCatalogStore.loadFromDisk();
    if (cached.isNotEmpty && state.isEmpty) {
      state = cached;
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
    for (final e in state) {
      if (historyEventIdsMatch(eventId, e.id) || e.id == key) return e;
    }
    return null;
  }

  EventDefinition? lookupByName(String eventName) {
    final name = eventName.trim();
    if (name.isEmpty) return null;
    EventDefinition? match;
    for (final e in state) {
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
      if (state.isNotEmpty) return;
      return;
    }
    state = cached;
  }

  Future<void> refreshFromRemote() async {
    final loggedIn = _ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) return;
    await _warmFromDisk();
    if (state.isEmpty) {
      await loadFromDisk();
    }
    final dn = _ref.read(deviceNoNotifierProvider).asData?.value;

    final sync = EventCatalogSync(_ref.read(authorizedApiClientProvider));
    final updated = await sync.refreshAndPersist(deviceNo: dn);
    _applyRefreshResult(updated, dn);
  }

  void _applyRefreshResult(List<EventDefinition>? updated, String? deviceNo) {
    if (updated == null) return;
    if (updated.isEmpty && state.isNotEmpty) {
      _debugLog('refresh skipped empty remote (keeping ${state.length} in memory)');
      return;
    }
    if (updated.isNotEmpty) {
      state = updated;
      _debugLog('refresh: ${updated.length} items (deviceNo=${deviceNo ?? "none"})');
    }
  }

  /// 先读盘再异步刷新；冷启动时若首次失败则短暂延迟后重试。
  Future<void> bootstrap({int maxAttempts = 3}) async {
    await _warmFromDisk();
    await loadFromDisk();
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (state.isNotEmpty && attempt > 1) break;
      await refreshFromRemote();
      if (state.isNotEmpty) break;
      if (attempt < maxAttempts) {
        _debugLog('bootstrap retry $attempt/$maxAttempts (catalog still empty)');
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    if (state.isEmpty) {
      _debugLog('bootstrap finished with empty catalog');
    }
  }
}

final eventCatalogProvider =
    StateNotifierProvider<EventCatalogNotifier, List<EventDefinition>>((ref) {
  return EventCatalogNotifier(ref);
});
