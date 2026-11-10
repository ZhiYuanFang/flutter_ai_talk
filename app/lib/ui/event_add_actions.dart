import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/event_button_usage_store.dart';
import '../data/appointment_event.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/history_post_outcome.dart';
import '../data/models.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/predict_post_mutation_scheduler.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import 'appointment_next_sheet.dart';
import 'event_catalog_picker_sheet.dart';
import 'event_record_sheet.dart';
import 'widgets/app_glass_overlay.dart';

/// 模块级单飞：防喂养格 / 预测卡连点重复提交。
var _eventAddInFlight = false;

bool get isEventAddInFlight => _eventAddInFlight;

/// 登录 + deviceNo 门闩（与喂养主页一致）。
Future<bool> ensureEventAddRemoteGate({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final loggedIn = ref.read(sessionProvider).isLoggedIn;
  if (!loggedIn) {
    final go = await showGlassConfirmDialog(
          context,
          title: '需要登录',
          message: '请先登录后再操作。',
          confirmLabel: '去登录',
        ) ??
        false;
    if (go && context.mounted) await context.push('/login');
    return false;
  }
  final dnState = ref.read(deviceNoNotifierProvider);
  if (dnState.isLoading) return true;
  final dn = dnState.asData?.value;
  if (dn == null || dn.isEmpty) {
    final go = await showGlassConfirmDialog(
          context,
          title: '绑定宝宝',
          message: '请先绑定宝宝信息。',
          confirmLabel: '去绑定',
        ) ??
        false;
    if (go && context.mounted) await context.push('/settings/bind-baby');
    return false;
  }
  return true;
}

bool _hasActiveTimingForEvent(WidgetRef ref, EventDefinition event) {
  final items = ref.read(homeHistoryProvider).items;
  for (final record in items) {
    if (!isActiveTimingRecord(record)) continue;
    if (historyEventIdsMatch(record.rawPayload['eventId'], event.id)) {
      return true;
    }
  }
  return false;
}

/// 提交结果：含是否本机乐观新插入（供喂养页登记 WS 飞入）。
class EventAddSubmitResult {
  const EventAddSubmitResult({
    required this.record,
    required this.insertedOptimistic,
  });

  final HistoryRecord record;
  final bool insertedOptimistic;
}

/// 提交一条历史事件；失败返回 null。
Future<EventAddSubmitResult?> submitEventAdd({
  required WidgetRef ref,
  required EventDefinition event,
  required int eventNumber,
  required DateTime startTime,
  required DateTime endTime,
  String remark = '',
}) async {
  if (_eventAddInFlight) return null;
  final dn = ref.read(deviceNoNotifierProvider).asData?.value;
  if (dn == null || dn.isEmpty) return null;
  // CRUD body 零 expect*；权威戳由静默锚点链 + expect-batch 写入
  final body = buildEventAddBody(
    deviceNo: dn,
    event: event,
    eventNumber: eventNumber,
    startTime: startTime,
    endTime: endTime,
    remark: remark,
  );

  _eventAddInFlight = true;
  try {
    final feed = ref.read(feedRepositoryProvider);
    final outcome = await feed.addHistoryEvent(body);
    if (!outcome.isSuccess) {
      if (outcome.failureKind == HistoryPostFailureKind.transport) {
        ref.showApiToast('同步失败，稍后请重试');
      }
      return null;
    }

    final serverId = outcome.serverId!;
    final record = historyRecordFromAddBody(body, id: serverId);
    final history = ref.read(homeHistoryProvider.notifier);
    final alreadyThere =
        ref.read(homeHistoryProvider).items.any((e) => e.id == serverId);
    if (alreadyThere) {
      history.upsertRecord(record);
    } else {
      // 真正追加：登记 awaiting，飞入仍由后续 WS 触发
      history.insertOptimistic(record);
      ref.read(historyEventFlyAwaitingProvider).register(serverId);
    }
    // 本机加餐后入队统一静默调度（不 await 管线网络）
    unawaited(
      schedulePredictPostHistoryMutation(ref, anchorHistoryId: serverId),
    );
    unawaited(EventButtonUsageStore.increment(event.id));
    return EventAddSubmitResult(
      record: record,
      insertedOptimistic: !alreadyThere,
    );
  } finally {
    _eventAddInFlight = false;
  }
}

/// 喂养事件格 / 预测网格卡共用：父→子选择后按类型添加或补充。
///
/// [directTimingAddOnHome]：仅喂养页传 true；`add`+`time` 跳过 sheet 直落库。
/// 预测页保持默认 false，仍开统一 Sheet。
Future<void> handleEventGridTap({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  Map<String, int>? usageCounts,
  FutureOr<void> Function(EventAddSubmitResult result)? onAdded,
  EventRecordIntent intent = EventRecordIntent.add,
  bool directTimingAddOnHome = false,
}) async {
  assert(intent != EventRecordIntent.edit);
  final catalog = ref.read(eventCatalogProvider).items;
  var target = event;
  if (hasChildren(catalog, event.id)) {
    // 多级选叶后仍走统一入口（由 _onEventButtonTap 收口）
    if (!context.mounted) return;
    final leaf = await showEventCatalogPickerSheet(
      context,
      catalog: catalog,
      root: event,
      usageCounts: usageCounts,
      onToast: (msg) => ref.showApiToast(msg),
    );
    if (leaf == null || !context.mounted) return;
    target = leaf;
  }
  await _onEventButtonTap(
    context: context,
    ref: ref,
    event: target,
    onAdded: onAdded,
    intent: intent,
    directTimingAddOnHome: directTimingAddOnHome,
  );
}

Future<void> _onEventButtonTap({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  FutureOr<void> Function(EventAddSubmitResult result)? onAdded,
  required EventRecordIntent intent,
  bool directTimingAddOnHome = false,
}) async {
  if (!event.hasValidEventType) return;
  if (_eventAddInFlight) return;
  if (!await ensureEventAddRemoteGate(context: context, ref: ref)) return;
  if (!context.mounted) return;

  final type = event.parsedEventType!;
  EventAddSubmitResult? submitted;

  // time：已在计时则 toast，add/supplement 均不重复开 sheet / 直落库
  if (type == EventCatalogEventType.time &&
      _hasActiveTimingForEvent(ref, event)) {
    ref.showApiToast('${event.name}已在计时中');
    return;
  }

  if (_eventAddInFlight) return;

  // 喂养页 add+time：跳过 sheet，直接开计时
  if (directTimingAddOnHome &&
      intent == EventRecordIntent.add &&
      type == EventCatalogEventType.time) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    submitted = await submitEventAdd(
      ref: ref,
      event: event,
      eventNumber: 0,
      startTime: start,
      endTime: DateTime.fromMillisecondsSinceEpoch(0),
      remark: '',
    );
  } else {
    // 其余：统一记录 sheet（取消不落库）
    final result = await showEventRecordCreateSheet(
      context,
      intent: intent,
      event: event,
    );
    if (result == null || !context.mounted || _eventAddInFlight) return;

    switch (type) {
      case EventCatalogEventType.time:
        final end = result.endTime ??
            DateTime.fromMillisecondsSinceEpoch(0);
        submitted = await submitEventAdd(
          ref: ref,
          event: event,
          eventNumber: result.eventNumber,
          startTime: result.startTime,
          endTime: end,
          remark: result.remark,
        );
      case EventCatalogEventType.one:
        submitted = await submitEventAdd(
          ref: ref,
          event: event,
          eventNumber: result.eventNumber,
          startTime: result.startTime,
          endTime: result.endTime ?? result.startTime,
          remark: result.remark,
        );
      case EventCatalogEventType.number:
        submitted = await submitEventAdd(
          ref: ref,
          event: event,
          eventNumber: result.eventNumber,
          startTime: result.startTime,
          endTime: result.startTime,
          remark: result.remark,
        );
    }
  }
  if (submitted != null && onAdded != null) {
    await onAdded(submitted);
  }
  // 预约：新增先清空再弹；补充仅空/过期弹
  if (submitted != null && context.mounted) {
    final catalog = ref.read(eventCatalogProvider).items;
    if (!eventIsAppointment(event, catalog)) return;
    if (intent == EventRecordIntent.add) {
      await clearThenPromptAppointmentNextAfterAdd(
        context: context,
        ref: ref,
        event: event,
        catalog: catalog,
      );
    } else {
      await maybePromptAppointmentNextAfterWrite(
        context: context,
        ref: ref,
        event: event,
        catalog: catalog,
      );
    }
  }
}
