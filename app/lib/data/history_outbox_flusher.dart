import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import 'history_mapper.dart';
import 'history_outbox_store.dart';
import 'models.dart';

Future<void>? _flushInFlight;

/// WS ready 触发的历史 outbox flush（single-flight）。
Future<void> flushHistoryOutbox(Ref ref) {
  return _flushInFlight ??= _flushHistoryOutboxImpl(ref).whenComplete(() {
    _flushInFlight = null;
  });
}

Future<void> _flushHistoryOutboxImpl(Ref ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final feed = ref.read(feedRepositoryProvider);
  if (!feed.isHistoryWebSocketReady) return;
  final dn = ref.read(deviceNoNotifierProvider).asData?.value;
  if (dn == null || dn.isEmpty) return;

  final history = ref.read(homeHistoryProvider.notifier);
  final pending = listPendingAddsInOrder(ref.read(homeHistoryProvider).items);
  AppDebugLog.historyOutbox('flush start device=$dn pending=${pending.length}');

  // 1) 先处理持久化 ADD outbox（若存在），保证持久化的新增先于 UPDATE 执行。
  while (true) {
    final headAdd = await HistoryOutboxStore.peekAdd(dn);
    if (headAdd == null) break;

    // 若本地 items 中已被移除，则直接弹出并继续。
    if (!ref.read(homeHistoryProvider).items.any((e) => e.id == headAdd.pendingId)) {
      await HistoryOutboxStore.removeHeadAdd(dn);
      continue;
    }

    // latest record will be read when building body if needed; no local placeholder required.
    final outcome = await feed.addHistoryEvent(headAdd.body);
    if (outcome.isSuccess) {
      history.replaceRecordId(headAdd.pendingId, outcome.serverId!);
      await HistoryOutboxStore.removeHeadAdd(dn);
      AppDebugLog.historyOutbox('add ok ${headAdd.pendingId}->${outcome.serverId}');
      continue;
    }
    if (outcome.isBusinessFailure) {
      history.removeById(headAdd.pendingId);
      await HistoryOutboxStore.removeHeadAdd(dn);
      AppDebugLog.historyOutbox('add business fail ${headAdd.pendingId}');
      continue;
    }
    AppDebugLog.historyOutbox('add transport fail ${headAdd.pendingId} stop batch');
    return;
  }

  // 2) 再处理内存中的 pending adds（来自立即插入的 optimistic rows）。
  for (final record in pending) {
    if (!ref.read(homeHistoryProvider).items.any((e) => e.id == record.id)) {
      continue;
    }
    final latest = ref
        .read(homeHistoryProvider)
        .items
        .firstWhere((e) => e.id == record.id, orElse: () => record);
    final outcome = await feed.addHistoryEvent(buildEventAddBodyFromPendingRecord(latest));
    if (outcome.isSuccess) {
      history.replaceRecordId(record.id, outcome.serverId!);
      AppDebugLog.historyOutbox('add ok ${record.id}->${outcome.serverId}');
      continue;
    }
    if (outcome.isBusinessFailure) {
      history.removeById(record.id);
      AppDebugLog.historyOutbox('add business fail ${record.id}');
      continue;
    }
    AppDebugLog.historyOutbox('add transport fail ${record.id} stop batch');
    return;
  }

  while (true) {
    final head = await HistoryOutboxStore.peek(dn);
    if (head == null) break;

    final outcome = await feed.postHistoryUpdateBody(head.body);
    if (outcome.isSuccess) {
      await HistoryOutboxStore.removeHead(dn);
      AppDebugLog.historyOutbox('update ok ${head.recordId}');
      continue;
    }
    if (outcome.isBusinessFailure) {
      await HistoryOutboxStore.removeHead(dn);
      final items = ref.read(homeHistoryProvider).items;
      final idx = items.indexWhere((e) => e.id == head.recordId);
      if (idx >= 0) {
        history.replaceRecordImmediate(_recordWithClearedEndTime(items[idx]));
      }
      AppDebugLog.historyOutbox('update business fail ${head.recordId}');
      continue;
    }
    AppDebugLog.historyOutbox('update transport fail ${head.recordId} stop batch');
    return;
  }

  AppDebugLog.historyOutbox('flush done device=$dn');
}

HistoryRecord _recordWithClearedEndTime(HistoryRecord record) {
  final p = Map<String, Object?>.from(record.rawPayload);
  p['endTime'] = 0;
  return HistoryRecord(
    id: record.id,
    createdAt: record.createdAt,
    eventName: record.eventName,
    action: record.action,
    rawPayload: p,
  );
}

/// 将 UPDATE 写入 outbox（WS 未就绪时 stop/update 路径）。
Future<void> enqueueHistoryUpdateOutbox({
  required String deviceNo,
  required String recordId,
  required Map<String, dynamic> body,
}) {
  return HistoryOutboxStore.enqueueUpdate(
    deviceNo: deviceNo,
    recordId: recordId,
    body: body,
  );
}

/// 登出或清缓存时丢弃 UPDATE outbox。
Future<void> clearHistoryUpdateOutbox({String? deviceNo}) async {
  if (deviceNo != null && deviceNo.isNotEmpty) {
    await HistoryOutboxStore.clearForDevice(deviceNo);
    return;
  }
  await HistoryOutboxStore.clearAll();
}

/// 从 home history items 移除 pending 行（登出对齐 spec）。
List<HistoryRecord> stripPendingHistoryRecords(List<HistoryRecord> items) {
  return items.where((e) => !isPendingHistoryId(e.id)).toList(growable: false);
}
