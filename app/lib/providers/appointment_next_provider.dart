import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../data/appointment_event.dart';
import '../data/appointment_next_repository.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'event_catalog_notifier.dart';
import 'predict_imminent_sync_provider.dart';
import 'session_provider.dart';

/// 根 eventId → 已拉取/写入的 nextAt 秒（含 0=无约定）。
final appointmentNextCacheProvider =
    NotifierProvider<AppointmentNextCacheNotifier, Map<String, int>>(
  AppointmentNextCacheNotifier.new,
);

class AppointmentNextCacheNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  /// 本地写入缓存（不打 HTTP）。
  void setLocal(String rootEventId, int nextAtSec) {
    final id = rootEventId.trim();
    if (id.isEmpty) return;
    final sec = nextAtSec < 0 ? 0 : nextAtSec;
    state = {...state, id: sec};
  }

  int? peek(String rootEventId) {
    final id = rootEventId.trim();
    if (id.isEmpty) return null;
    return state[id];
  }

  bool isKnown(String rootEventId) => state.containsKey(rootEventId.trim());
}

final appointmentNextRepositoryProvider =
    Provider<AppointmentNextRepository>((ref) {
  return AppointmentNextRepository(ref.watch(authorizedApiClientProvider));
});

final _appointmentFetchInFlight = <String, Future<int>>{};

String? _deviceNoOrEmpty(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return '';
  return (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
          .asData
          ?.value
          ?.trim() ??
      '';
}

/// 确保缓存中有该根 nextAt；已有则直接返回。
Future<int> ensureAppointmentNextAt(dynamic ref, String rootEventId) async {
  final root = rootEventId.trim();
  if (root.isEmpty) return 0;
  final cache = ref.read(appointmentNextCacheProvider.notifier)
      as AppointmentNextCacheNotifier;
  if (cache.isKnown(root)) return cache.peek(root) ?? 0;

  final existing = _appointmentFetchInFlight[root];
  if (existing != null) return existing;

  final fut = () async {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) return 0;
    try {
      final repo = ref.read(appointmentNextRepositoryProvider)
          as AppointmentNextRepository;
      final sec = await repo.getNextAt(deviceNo: dn, eventId: root);
      cache.setLocal(root, sec);
      return sec;
    } catch (e) {
      AppDebugLog.appointmentNext('ensure GET err=$e root=$root');
      return cache.peek(root) ?? 0;
    } finally {
      _appointmentFetchInFlight.remove(root);
    }
  }();
  _appointmentFetchInFlight[root] = fut;
  return fut;
}

/// 预取目录中全部预约根（预测页挂载时调用；single-flight per root）。
Future<void> prefetchAppointmentNextForCatalog(dynamic ref) async {
  final catalog = ref.read(eventCatalogProvider).items as List<EventDefinition>;
  final roots = rootEvents(catalog);
  final futures = <Future<void>>[];
  for (final r in roots) {
    if (!catalogRootIsAppointment(r.id, catalog)) continue;
    futures.add(ensureAppointmentNextAt(ref, r.id).then((_) {}));
  }
  if (futures.isEmpty) return;
  await Future.wait(futures);
}

/// 预测页 watch：catalog 就绪后预取预约约定（用户打开预测页才触发）。
final appointmentNextPrefetchProvider = FutureProvider.autoDispose<void>((ref) async {
  final items = ref.watch(eventCatalogProvider).items;
  if (items.isEmpty) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  await prefetchAppointmentNextForCatalog(ref);
});

/// PUT 约定并更新缓存，成功后触发 pending 同步。
Future<bool> putAppointmentNextAt({
  required dynamic ref,
  required String rootEventId,
  required int nextAtSec,
}) async {
  final root = rootEventId.trim();
  final dn = _deviceNoOrEmpty(ref);
  if (root.isEmpty || dn == null || dn.isEmpty) return false;
  try {
    final repo = ref.read(appointmentNextRepositoryProvider)
        as AppointmentNextRepository;
    final sec = nextAtSec < 0 ? 0 : nextAtSec;
    await repo.putNextAt(deviceNo: dn, eventId: root, nextAt: sec);
    (ref.read(appointmentNextCacheProvider.notifier)
            as AppointmentNextCacheNotifier)
        .setLocal(root, sec);
    unawaited(requestPredictImminentPendingSync(ref));
    return true;
  } catch (e) {
    AppDebugLog.appointmentNext('PUT err=$e root=$root');
    return false;
  }
}

/// 清空约定（编辑页专用）。
Future<bool> clearAppointmentNextAt({
  required dynamic ref,
  required String rootEventId,
}) {
  return putAppointmentNextAt(
    ref: ref,
    rootEventId: rootEventId,
    nextAtSec: 0,
  );
}
