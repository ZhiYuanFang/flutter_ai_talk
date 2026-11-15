import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../config/appointment_local_cache_store.dart';
import '../data/appointment_event.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import 'device_no_notifier.dart';
import 'event_catalog_notifier.dart';
import 'repositories.dart';
import 'session_provider.dart';

/// 预约根不限窗「上一次」：时间 + history remark（Go filter id DESC）。
class AppointmentLastOccurrence {
  const AppointmentLastOccurrence({
    this.at,
    this.remark = '',
  });

  /// null 表示已确认无历史。
  final DateTime? at;

  /// history.remark 原样（展示前可 trim 判空）。
  final String remark;
}

/// 根 eventId → 已解析的不限窗上次（含确认无记录）。
final appointmentLastCacheProvider = NotifierProvider<
    AppointmentLastCacheNotifier, Map<String, AppointmentLastOccurrence>>(
  AppointmentLastCacheNotifier.new,
);

class AppointmentLastCacheNotifier
    extends Notifier<Map<String, AppointmentLastOccurrence>> {
  @override
  Map<String, AppointmentLastOccurrence> build() => const {};

  void setLocal(
    String rootEventId,
    AppointmentLastOccurrence value, {
    bool persist = true,
  }) {
    final id = rootEventId.trim();
    if (id.isEmpty) return;
    state = {...state, id: value};
    if (persist) {
      unawaited(_persistAll());
    }
  }

  void hydrateAll(Map<String, AppointmentLastOccurrence> map) {
    if (map.isEmpty) return;
    state = {...state, ...map};
  }

  void clearAll() {
    state = const {};
  }

  AppointmentLastOccurrence? peek(String rootEventId) {
    final id = rootEventId.trim();
    if (id.isEmpty) return null;
    return state[id];
  }

  bool isKnown(String rootEventId) => state.containsKey(rootEventId.trim());

  Future<void> _persistAll() async {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) return;
    final raw = <String, Map<String, Object?>>{
      for (final e in state.entries)
        e.key: {
          if (e.value.at != null)
            'at': e.value.at!.toUtc().toIso8601String(),
          'remark': e.value.remark,
          'empty': e.value.at == null,
        },
    };
    await AppointmentLocalCacheStore.saveLastRaw(dn, raw);
  }
}

final _appointmentLastInFlight = <String, Future<AppointmentLastOccurrence>>{};

/// filter 失败后短冷却，避免卡 rebuild 连打（静默刷新可绕过）。
final _appointmentLastCooldownUntil = <String, DateTime>{};

String? _deviceNoOrEmpty(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return '';
  return (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
          .asData
          ?.value
          ?.trim() ??
      '';
}

/// 从磁盘 hydrate last 进内存。
Future<void> hydrateAppointmentLastFromDisk(dynamic ref) async {
  final dn = _deviceNoOrEmpty(ref);
  if (dn == null || dn.isEmpty) return;
  final raw = await AppointmentLocalCacheStore.loadLastRaw(dn);
  if (raw.isEmpty) return;
  final map = <String, AppointmentLastOccurrence>{};
  for (final e in raw.entries) {
    final atRaw = e.value['at']?.toString() ?? '';
    final at = atRaw.isEmpty ? null : DateTime.tryParse(atRaw)?.toLocal();
    final remark = e.value['remark']?.toString() ?? '';
    final knownEmpty = e.value['empty'] == true || e.value['empty'] == 1;
    if (at == null && !knownEmpty) continue;
    map[e.key] = AppointmentLastOccurrence(at: at, remark: remark);
  }
  (ref.read(appointmentLastCacheProvider.notifier)
          as AppointmentLastCacheNotifier)
      .hydrateAll(map);
  AppDebugLog.appointmentNext('hydrate last count=${map.length}');
}

/// 静默不限窗 filter（已知也打）；失败保留缓存、可冷却。
Future<AppointmentLastOccurrence> refreshAppointmentLastSilent(
  dynamic ref,
  String rootEventId, {
  List<EventDefinition>? catalogOverride,
  bool bypassCooldown = false,
}) async {
  final root = rootEventId.trim();
  if (root.isEmpty) {
    return const AppointmentLastOccurrence();
  }
  final cache = ref.read(appointmentLastCacheProvider.notifier)
      as AppointmentLastCacheNotifier;

  if (!bypassCooldown) {
    final coolUntil = _appointmentLastCooldownUntil[root];
    if (coolUntil != null && coolUntil.isAfter(DateTime.now())) {
      return cache.peek(root) ?? const AppointmentLastOccurrence();
    }
  }

  final existing = _appointmentLastInFlight[root];
  if (existing != null) return existing;

  final fut = () async {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) {
      return cache.peek(root) ?? const AppointmentLastOccurrence();
    }
    try {
      final catalog = catalogOverride ??
          (ref.read(eventCatalogProvider).items as List<EventDefinition>);
      final ids = catalogSubtreeEventIds(catalog, root);
      final eventIds = ids.join(',');
      final feed = ref.read(feedRepositoryProvider);
      final list = await feed.tryLoadHistoryFilter(
        eventIds: eventIds,
        limit: 1,
        ignoreTimeRange: true,
      );
      if (list == null) {
        AppDebugLog.appointmentNext(
          'last filter fail root=$root (cooldown)',
        );
        _appointmentLastCooldownUntil[root] =
            DateTime.now().add(const Duration(seconds: 30));
        return cache.peek(root) ?? const AppointmentLastOccurrence();
      }
      _appointmentLastCooldownUntil.remove(root);
      AppointmentLastOccurrence value;
      if (list.isEmpty) {
        value = const AppointmentLastOccurrence();
      } else {
        final rec = list.first;
        final at = occurrenceInstant(rec, includeActive: true);
        final remark = (rec.rawPayload['remark'] as String?) ?? '';
        value = AppointmentLastOccurrence(at: at, remark: remark);
      }
      cache.setLocal(root, value);
      AppDebugLog.appointmentNext(
        'last filter ok root=$root hasAt=${value.at != null} '
        'remarkLen=${value.remark.runes.length}',
      );
      return value;
    } catch (e) {
      AppDebugLog.appointmentNext('last filter err=$e root=$root');
      _appointmentLastCooldownUntil[root] =
          DateTime.now().add(const Duration(seconds: 30));
      return cache.peek(root) ?? const AppointmentLastOccurrence();
    } finally {
      _appointmentLastInFlight.remove(root);
    }
  }();
  _appointmentLastInFlight[root] = fut;
  return fut;
}

/// 确保缓存中有该预约根的不限窗上次；已有则直接返回。
Future<AppointmentLastOccurrence> ensureAppointmentLastOccurrence(
  dynamic ref,
  String rootEventId, {
  List<EventDefinition>? catalogOverride,
}) async {
  final root = rootEventId.trim();
  if (root.isEmpty) {
    return const AppointmentLastOccurrence();
  }
  final cache = ref.read(appointmentLastCacheProvider.notifier)
      as AppointmentLastCacheNotifier;
  if (cache.isKnown(root)) {
    return cache.peek(root) ?? const AppointmentLastOccurrence();
  }
  return refreshAppointmentLastSilent(
    ref,
    root,
    catalogOverride: catalogOverride,
  );
}

/// 点按编辑：不限窗 filter 再取最近一条真 History（single-flight per root）。
/// 成功时顺带刷新展示用 last 缓存；失败/空返回 null（调用方 toast，不开空 sheet）。
final _appointmentLastEditInFlight = <String, Future<HistoryRecord?>>{};

Future<HistoryRecord?> fetchAppointmentLastHistoryRecord(
  dynamic ref,
  String rootEventId, {
  List<EventDefinition>? catalogOverride,
}) async {
  final root = rootEventId.trim();
  if (root.isEmpty) return null;

  final existing = _appointmentLastEditInFlight[root];
  if (existing != null) return existing;

  final Future<HistoryRecord?> fut =
      _fetchAppointmentLastHistoryRecordBody(ref, root, catalogOverride);
  _appointmentLastEditInFlight[root] = fut;
  return fut;
}

Future<HistoryRecord?> _fetchAppointmentLastHistoryRecordBody(
  dynamic ref,
  String root,
  List<EventDefinition>? catalogOverride,
) async {
  try {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) return null;
    final catalog = catalogOverride ??
        (ref.read(eventCatalogProvider).items as List<EventDefinition>);
    final ids = catalogSubtreeEventIds(catalog, root);
    final feed = ref.read(feedRepositoryProvider);
    final list = await feed.tryLoadHistoryFilter(
      eventIds: ids.join(','),
      limit: 1,
      ignoreTimeRange: true,
    );
    if (list == null || list.isEmpty) {
      AppDebugLog.appointmentNext(
        'last edit filter empty/fail root=$root',
      );
      return null;
    }
    final rec = list.first;
    final at = occurrenceInstant(rec, includeActive: true);
    final remark = (rec.rawPayload['remark'] as String?) ?? '';
    // 展示缓存与编辑同源对齐
    (ref.read(appointmentLastCacheProvider.notifier)
            as AppointmentLastCacheNotifier)
        .setLocal(
      root,
      AppointmentLastOccurrence(at: at, remark: remark),
    );
    AppDebugLog.appointmentNext('last edit filter ok root=$root');
    return rec;
  } catch (e) {
    AppDebugLog.appointmentNext('last edit filter err=$e root=$root');
    return null;
  } finally {
    _appointmentLastEditInFlight.remove(root);
  }
}

/// 预测页：hydrate + 全部预约根静默刷新 last。
Future<void> prefetchAppointmentLastForCatalog(dynamic ref) async {
  await hydrateAppointmentLastFromDisk(ref);
  final catalog = ref.read(eventCatalogProvider).items as List<EventDefinition>;
  final roots = rootEvents(catalog);
  final futures = <Future<void>>[];
  for (final r in roots) {
    if (!catalogRootIsAppointment(r.id, catalog)) continue;
    futures.add(
      refreshAppointmentLastSilent(ref, r.id, catalogOverride: catalog)
          .then((_) {}),
    );
  }
  if (futures.isEmpty) return;
  await Future.wait(futures);
}

/// 预测页下拉：全部预约根静默刷新 last（绕过冷却）。
Future<void> refreshAllAppointmentLastSilent(dynamic ref) async {
  final catalog = ref.read(eventCatalogProvider).items as List<EventDefinition>;
  final roots = rootEvents(catalog);
  final futures = <Future<void>>[];
  for (final r in roots) {
    if (!catalogRootIsAppointment(r.id, catalog)) continue;
    futures.add(
      refreshAppointmentLastSilent(
        ref,
        r.id,
        catalogOverride: catalog,
        bypassCooldown: true,
      ).then((_) {}),
    );
  }
  if (futures.isEmpty) return;
  await Future.wait(futures);
}

/// 预测页挂载时预取（与 appointmentNextPrefetch 同触发面；watch deviceNo）。
final appointmentLastPrefetchProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final items = ref.watch(eventCatalogProvider).items;
  if (items.isEmpty) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final dn =
      ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  if (dn.isEmpty) {
    await hydrateAppointmentLastFromDisk(ref);
    return;
  }
  await prefetchAppointmentLastForCatalog(ref);
});
