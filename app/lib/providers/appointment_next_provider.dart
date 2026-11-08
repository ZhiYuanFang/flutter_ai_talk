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

/// 根 eventId → 已拉取/写入的 nextAt+remark（含 nextAt=0=无约定）。
final appointmentNextCacheProvider = NotifierProvider<
    AppointmentNextCacheNotifier, Map<String, AppointmentNextValue>>(
  AppointmentNextCacheNotifier.new,
);

class AppointmentNextCacheNotifier
    extends Notifier<Map<String, AppointmentNextValue>> {
  @override
  Map<String, AppointmentNextValue> build() => const {};

  /// 本地写入缓存（不打 HTTP）。
  void setLocal(String rootEventId, AppointmentNextValue value) {
    final id = rootEventId.trim();
    if (id.isEmpty) return;
    final sec = value.nextAtSec < 0 ? 0 : value.nextAtSec;
    state = {
      ...state,
      id: AppointmentNextValue(nextAtSec: sec, remark: value.remark),
    };
  }

  AppointmentNextValue? peek(String rootEventId) {
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

final _appointmentFetchInFlight = <String, Future<AppointmentNextValue>>{};

String? _deviceNoOrEmpty(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return '';
  return (ref.read(deviceNoNotifierProvider) as AsyncValue<String?>)
          .asData
          ?.value
          ?.trim() ??
      '';
}

/// 确保缓存中有该根约定；已有则直接返回。
Future<AppointmentNextValue> ensureAppointmentNext(
  dynamic ref,
  String rootEventId,
) async {
  final root = rootEventId.trim();
  if (root.isEmpty) return AppointmentNextValue.empty;
  final cache = ref.read(appointmentNextCacheProvider.notifier)
      as AppointmentNextCacheNotifier;
  if (cache.isKnown(root)) {
    return cache.peek(root) ?? AppointmentNextValue.empty;
  }

  final existing = _appointmentFetchInFlight[root];
  if (existing != null) return existing;

  final fut = () async {
    final dn = _deviceNoOrEmpty(ref);
    if (dn == null || dn.isEmpty) return AppointmentNextValue.empty;
    try {
      final repo = ref.read(appointmentNextRepositoryProvider)
          as AppointmentNextRepository;
      final value = await repo.getNext(deviceNo: dn, eventId: root);
      cache.setLocal(root, value);
      return value;
    } catch (e) {
      AppDebugLog.appointmentNext('ensure GET err=$e root=$root');
      return cache.peek(root) ?? AppointmentNextValue.empty;
    } finally {
      _appointmentFetchInFlight.remove(root);
    }
  }();
  _appointmentFetchInFlight[root] = fut;
  return fut;
}

/// 兼容旧调用：仅取 nextAt 秒。
Future<int> ensureAppointmentNextAt(dynamic ref, String rootEventId) async {
  final v = await ensureAppointmentNext(ref, rootEventId);
  return v.nextAtSec;
}

/// 预取目录中全部预约根（预测页挂载时调用；single-flight per root）。
Future<void> prefetchAppointmentNextForCatalog(dynamic ref) async {
  final catalog = ref.read(eventCatalogProvider).items as List<EventDefinition>;
  final roots = rootEvents(catalog);
  final futures = <Future<void>>[];
  for (final r in roots) {
    if (!catalogRootIsAppointment(r.id, catalog)) continue;
    futures.add(ensureAppointmentNext(ref, r.id).then((_) {}));
  }
  if (futures.isEmpty) return;
  await Future.wait(futures);
}

/// 预测页 watch：catalog 就绪后预取预约约定（用户打开预测页才触发）。
final appointmentNextPrefetchProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final items = ref.watch(eventCatalogProvider).items;
  if (items.isEmpty) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  await prefetchAppointmentNextForCatalog(ref);
});

/// PUT 约定并更新缓存，成功后触发 pending 同步；MUST 始终传 remark。
Future<bool> putAppointmentNext({
  required dynamic ref,
  required String rootEventId,
  required int nextAtSec,
  required String remark,
}) async {
  final root = rootEventId.trim();
  final dn = _deviceNoOrEmpty(ref);
  if (root.isEmpty || dn == null || dn.isEmpty) return false;
  try {
    final repo = ref.read(appointmentNextRepositoryProvider)
        as AppointmentNextRepository;
    final sec = nextAtSec < 0 ? 0 : nextAtSec;
    // nextAt=0 时仍传 remark（服务端强制清）；本地缓存同步清空备注
    final storedRemark = sec == 0 ? '' : clampAppointmentRemark(remark);
    await repo.putNext(
      deviceNo: dn,
      eventId: root,
      nextAt: sec,
      remark: clampAppointmentRemark(remark),
    );
    (ref.read(appointmentNextCacheProvider.notifier)
            as AppointmentNextCacheNotifier)
        .setLocal(
      root,
      AppointmentNextValue(nextAtSec: sec, remark: storedRemark),
    );
    unawaited(requestPredictImminentPendingSync(ref));
    return true;
  } catch (e) {
    AppDebugLog.appointmentNext('PUT err=$e root=$root');
    return false;
  }
}

/// 兼容旧调用：仅写 nextAt（remark 取缓存或空串）。
Future<bool> putAppointmentNextAt({
  required dynamic ref,
  required String rootEventId,
  required int nextAtSec,
}) async {
  final cache = ref.read(appointmentNextCacheProvider.notifier)
      as AppointmentNextCacheNotifier;
  final existing = cache.peek(rootEventId);
  return putAppointmentNext(
    ref: ref,
    rootEventId: rootEventId,
    nextAtSec: nextAtSec,
    remark: nextAtSec == 0 ? '' : (existing?.remark ?? ''),
  );
}

/// 清空约定（编辑页专用）；服务端清备注。
Future<bool> clearAppointmentNextAt({
  required dynamic ref,
  required String rootEventId,
}) {
  return putAppointmentNext(
    ref: ref,
    rootEventId: rootEventId,
    nextAtSec: 0,
    remark: '',
  );
}
