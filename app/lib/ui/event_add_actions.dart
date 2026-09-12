import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/event_button_usage_store.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/history_post_outcome.dart';
import '../data/models.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
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
      history.insertOptimistic(record);
    }
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
/// [intent]：`supplement` 开统一 Sheet；`add` 非量直接 now，number 开 Sheet。
/// [confirmDirectLeafBeforeAdd]：仅 `add` + 预测直点叶子 + 非 number 时先确认。
Future<void> handleEventGridTap({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  Map<String, int>? usageCounts,
  FutureOr<void> Function(EventAddSubmitResult result)? onAdded,
  bool confirmDirectLeafBeforeAdd = false,
  EventRecordIntent intent = EventRecordIntent.add,
}) async {
  assert(intent != EventRecordIntent.edit);
  final catalog = ref.read(eventCatalogProvider).items;
  var target = event;
  if (hasChildren(catalog, event.id)) {
    // picker 选叶子后不再确认
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
  } else if (intent == EventRecordIntent.add && confirmDirectLeafBeforeAdd) {
    // 直点叶子：仅普通新增的 time/one 确认；补充走 Sheet；number 已有 sheet
    final type = target.parsedEventType;
    if (type != null && type != EventCatalogEventType.number) {
      if (!context.mounted) return;
      final ok = await showGlassConfirmDialog(
            context,
            title: '确认添加',
            message: '是否添加「${target.name}」？',
            confirmLabel: '添加',
          ) ??
          false;
      if (!ok || !context.mounted) return;
    }
  }
  await _onEventButtonTap(
    context: context,
    ref: ref,
    event: target,
    onAdded: onAdded,
    intent: intent,
  );
}

Future<void> _onEventButtonTap({
  required BuildContext context,
  required WidgetRef ref,
  required EventDefinition event,
  FutureOr<void> Function(EventAddSubmitResult result)? onAdded,
  required EventRecordIntent intent,
}) async {
  if (!event.hasValidEventType) return;
  if (_eventAddInFlight) return;
  if (!await ensureEventAddRemoteGate(context: context, ref: ref)) return;
  if (!context.mounted) return;

  final type = event.parsedEventType!;
  EventAddSubmitResult? submitted;

  if (intent == EventRecordIntent.supplement) {
    // 补充：任意类型开统一 Sheet
    if (type == EventCatalogEventType.time &&
        _hasActiveTimingForEvent(ref, event)) {
      ref.showApiToast('${event.name}已在计时中');
      return;
    }
    if (_eventAddInFlight) return;
    final result = await showEventRecordCreateSheet(
      context,
      intent: EventRecordIntent.supplement,
      event: event,
    );
    if (result == null || !context.mounted || _eventAddInFlight) return;
    final end = result.endTime ??
        (type == EventCatalogEventType.time
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : result.startTime);
    submitted = await submitEventAdd(
      ref: ref,
      event: event,
      eventNumber: result.eventNumber,
      startTime: result.startTime,
      endTime: end,
      remark: result.remark,
    );
  } else {
    // 普通新增
    switch (type) {
      case EventCatalogEventType.time:
        if (_hasActiveTimingForEvent(ref, event)) {
          ref.showApiToast('${event.name}已在计时中');
          return;
        }
        final now = DateTime.now();
        submitted = await submitEventAdd(
          ref: ref,
          event: event,
          eventNumber: 0,
          startTime: now,
          endTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
      case EventCatalogEventType.one:
        final now = DateTime.now();
        submitted = await submitEventAdd(
          ref: ref,
          event: event,
          eventNumber: 1,
          startTime: now,
          endTime: now,
        );
      case EventCatalogEventType.number:
        if (_eventAddInFlight) return;
        final result = await showEventRecordCreateSheet(
          context,
          intent: EventRecordIntent.add,
          event: event,
        );
        if (result == null || !context.mounted || _eventAddInFlight) return;
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
}
