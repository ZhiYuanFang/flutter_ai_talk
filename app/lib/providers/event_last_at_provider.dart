import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/event_last_at_store.dart';
import '../data/active_timing_stop.dart';
import '../data/event_branding.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import '../data/smart_prediction_rows.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

/// 当前宝宝：根 eventId → 本机曾见真喂养最新发生时刻。
final eventLastAtCacheProvider =
    AsyncNotifierProvider<EventLastAtCacheNotifier, Map<String, DateTime>>(
  EventLastAtCacheNotifier.new,
);

class EventLastAtCacheNotifier extends AsyncNotifier<Map<String, DateTime>> {
  String _deviceNo = '';

  @override
  Future<Map<String, DateTime>> build() async {
    // deviceNo 变化时重建，避免串读另一宝宝
    final dn =
        ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
    _deviceNo = dn;
    if (dn.isEmpty || !ref.watch(sessionProvider).isLoggedIn) {
      return {};
    }
    return EventLastAtStore.load(dn);
  }

  Map<String, DateTime> _current() =>
      state.asData?.value ?? const <String, DateTime>{};

  /// 观察一条真发生：cache = max(旧, at)。
  Future<void> observe(String rootEventId, DateTime at) async {
    final root = rootEventId.trim();
    final dn = _deviceNo;
    if (root.isEmpty || dn.isEmpty) return;
    final cur = Map<String, DateTime>.from(_current());
    final prev = cur[root];
    if (prev != null && !at.isAfter(prev)) return;
    cur[root] = at;
    state = AsyncData(cur);
    await EventLastAtStore.save(dn, cur);
  }

  /// 批量 max 写入（home∪range 合并后）。
  Future<void> observeMany(Map<String, DateTime> tips) async {
    final dn = _deviceNo;
    if (dn.isEmpty || tips.isEmpty) return;
    final cur = Map<String, DateTime>.from(_current());
    var changed = false;
    for (final e in tips.entries) {
      final root = e.key.trim();
      if (root.isEmpty) continue;
      final prev = cur[root];
      if (prev != null && !e.value.isAfter(prev)) continue;
      cur[root] = e.value;
      changed = true;
    }
    if (!changed) return;
    state = AsyncData(cur);
    await EventLastAtStore.save(dn, cur);
  }

  /// 删除可能打到 tip：按仍可见最新重算，或清键。
  Future<void> invalidateTip({
    required String rootEventId,
    required DateTime deletedAt,
    DateTime? visibleLatest,
  }) async {
    final root = rootEventId.trim();
    final dn = _deviceNo;
    if (root.isEmpty || dn.isEmpty) return;
    final cur = Map<String, DateTime>.from(_current());
    final tip = cur[root];
    if (tip == null) return;
    // 删除早于 tip：不动
    if (deletedAt.isBefore(tip)) return;
    if (visibleLatest != null) {
      cur[root] = visibleLatest;
    } else {
      cur.remove(root);
    }
    state = AsyncData(cur);
    await EventLastAtStore.save(dn, cur);
  }

  /// 切换/注销前清盘并清空内存。
  Future<void> clearForWipe() async {
    final dn = _deviceNo;
    if (dn.isNotEmpty) {
      await EventLastAtStore.clearDevice(dn);
    }
    state = const AsyncData({});
  }
}

/// 从 map 取根 tip（含 catalogIdsEqual 模糊匹配）。
DateTime? lookupEventLastAtCache(
  Map<String, DateTime> cache,
  String rootEventId,
) {
  final root = rootEventId.trim();
  if (root.isEmpty) return null;
  final direct = cache[root];
  if (direct != null) return direct;
  for (final e in cache.entries) {
    if (catalogIdsEqual(e.key, root)) return e.value;
  }
  return null;
}

/// 真历史入内存时 max 刷新缓存（不处理删除；删除走 [invalidateEventLastAtForRemovedRecord]）。
void scheduleEventLastAtObserveFromHistory(
  Ref ref,
  List<HistoryRecord> real,
  List<EventDefinition> catalog,
) {
  Future.microtask(() async {
    final dn =
        ref.read(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
    if (dn.isEmpty || !ref.read(sessionProvider).isLoggedIn) return;
    final tips = <String, DateTime>{};
    for (final r in real) {
      if (isPredictionRecallSeedRecord(r)) continue;
      final at = occurrenceInstant(r, includeActive: true);
      if (at == null) continue;
      final id = historyRecordEventId(r);
      final root = id.isNotEmpty
          ? rootEventIdForCatalog(id, catalog)
          : (lookupEventForRecord(catalog, r)?.id.trim() ?? '');
      if (root.isEmpty) continue;
      final prev = tips[root];
      if (prev == null || at.isAfter(prev)) tips[root] = at;
    }
    if (tips.isEmpty) return;
    await ref.read(eventLastAtCacheProvider.notifier).observeMany(tips);
  });
}

/// 显式删除一条真记录后：若打到 tip 则重算/清键。
Future<void> invalidateEventLastAtForRemovedRecord(
  Ref ref, {
  required HistoryRecord removed,
  required List<EventDefinition> catalog,
  required List<HistoryRecord> visibleAfter,
}) async {
  if (isPredictionRecallSeedRecord(removed)) return;
  final at = occurrenceInstant(removed, includeActive: true);
  if (at == null) return;
  final id = historyRecordEventId(removed);
  final root = id.isNotEmpty
      ? rootEventIdForCatalog(id, catalog)
      : (lookupEventForRecord(catalog, removed)?.id.trim() ?? '');
  if (root.isEmpty) return;
  final byRoot = groupHistoryByRootEvent(
    history: visibleAfter,
    catalog: catalog,
  );
  List<HistoryRecord> bucket = byRoot[root] ?? const [];
  if (bucket.isEmpty) {
    for (final e in byRoot.entries) {
      if (catalogIdsEqual(e.key, root)) {
        bucket = e.value;
        break;
      }
    }
  }
  final visibleLatest = latestOccurrenceAtForRecords(bucket);
  await ref.read(eventLastAtCacheProvider.notifier).invalidateTip(
        rootEventId: root,
        deletedAt: at,
        visibleLatest: visibleLatest,
      );
}
