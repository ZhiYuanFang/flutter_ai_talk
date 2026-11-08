import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
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

  void setLocal(String rootEventId, AppointmentLastOccurrence value) {
    final id = rootEventId.trim();
    if (id.isEmpty) return;
    state = {...state, id: value};
  }

  AppointmentLastOccurrence? peek(String rootEventId) {
    final id = rootEventId.trim();
    if (id.isEmpty) return null;
    return state[id];
  }

  bool isKnown(String rootEventId) => state.containsKey(rootEventId.trim());
}

final _appointmentLastInFlight = <String, Future<AppointmentLastOccurrence>>{};

/// filter 失败后短冷却，避免卡 rebuild 连打。
final _appointmentLastCooldownUntil = <String, DateTime>{};

String? _deviceNoOrEmpty(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return '';
  return (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
          .asData
          ?.value
          ?.trim() ??
      '';
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

  final coolUntil = _appointmentLastCooldownUntil[root];
  if (coolUntil != null && coolUntil.isAfter(DateTime.now())) {
    return const AppointmentLastOccurrence();
  }

  final existing = _appointmentLastInFlight[root];
  if (existing != null) return existing;

  final fut = () async {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) {
      return const AppointmentLastOccurrence();
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
        // 失败不写入成功缓存，冷却后再试
        return const AppointmentLastOccurrence();
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
      return const AppointmentLastOccurrence();
    } finally {
      _appointmentLastInFlight.remove(root);
    }
  }();
  _appointmentLastInFlight[root] = fut;
  return fut;
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

/// 预测页：为目录中全部预约根预取不限窗上次（single-flight per root）。
Future<void> prefetchAppointmentLastForCatalog(dynamic ref) async {
  final catalog = ref.read(eventCatalogProvider).items as List<EventDefinition>;
  final roots = rootEvents(catalog);
  final futures = <Future<void>>[];
  for (final r in roots) {
    if (!catalogRootIsAppointment(r.id, catalog)) continue;
    futures.add(ensureAppointmentLastOccurrence(ref, r.id, catalogOverride: catalog)
        .then((_) {}));
  }
  if (futures.isEmpty) return;
  await Future.wait(futures);
}

/// 预测页挂载时预取（与 appointmentNextPrefetch 同触发面）。
final appointmentLastPrefetchProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final items = ref.watch(eventCatalogProvider).items;
  if (items.isEmpty) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  await prefetchAppointmentLastForCatalog(ref);
});
