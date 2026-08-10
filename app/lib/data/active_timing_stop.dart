import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_branding.dart';
import 'event_definition.dart';
import 'history_line_format.dart';
import 'history_mapper.dart';
import 'models.dart';
import '../providers/home_history_notifier.dart';
import '../providers/repositories.dart';
import '../providers/toast_bus.dart';

/// 将记录结束时间写入 payload（本地乐观更新用）。
HistoryRecord historyRecordWithEndTime(HistoryRecord r, DateTime end) {
  final p = Map<String, Object?>.from(r.rawPayload);
  p['endTime'] = historyDateTimeToUnixSeconds(end);
  return HistoryRecord(
    id: r.id,
    createdAt: r.createdAt,
    eventName: r.eventName,
    action: r.action,
    rawPayload: p,
  );
}

/// 目录内解析根事件 id（与预测分组一致）。
String rootEventIdForCatalog(String eventId, List<EventDefinition> catalog) {
  final idToDef = <String, EventDefinition>{};
  for (final d in catalog) {
    if (d.id.isNotEmpty) idToDef[d.id] = d;
  }
  var cur = eventId.trim();
  if (cur.isEmpty) return cur;
  final seen = <String>{};
  while (true) {
    if (seen.contains(cur)) return cur;
    seen.add(cur);
    final def = idToDef[cur];
    final p = def?.parentId?.trim();
    if (p == null || p.isEmpty) return cur;
    cur = p;
  }
}

/// 某根事件下最新一条进行中计时；无则 null。
HistoryRecord? findLatestActiveTimingForRoot({
  required List<HistoryRecord> items,
  required String rootEventId,
  required List<EventDefinition> catalog,
}) {
  final root = rootEventId.trim();
  if (root.isEmpty) return null;
  HistoryRecord? best;
  DateTime? bestStart;
  for (final r in items) {
    if (!isActiveTimingRecord(r)) continue;
    final id = historyRecordEventId(r);
    final recordRoot = id.isNotEmpty
        ? rootEventIdForCatalog(id, catalog)
        : '';
    final matches = recordRoot == root ||
        historyEventIdsMatch(r.rawPayload['eventId'], root);
    if (!matches) continue;
    final start = activeTimingStartAt(r);
    if (best == null || start.isAfter(bestStart!)) {
      best = r;
      bestStart = start;
    }
  }
  return best;
}

/// 停止进行中计时：写 endTime、无确认；成功则即时替换本地历史。
Future<bool> stopActiveTimingRecord({
  required WidgetRef ref,
  required HistoryRecord record,
}) async {
  final end = DateTime.now();
  final p = record.rawPayload;
  final remark = (p['remark'] as String?) ?? '';
  final feed = ref.read(feedRepositoryProvider);
  final history = ref.read(homeHistoryProvider.notifier);

  if (isPendingHistoryId(record.id)) {
    history.replaceRecordImmediate(historyRecordWithEndTime(record, end));
    return true;
  }

  final ok = await feed.updateHistoryRecord(
    record.id,
    remark: remark,
    startTime: activeTimingStartAt(record),
    endTime: end,
    fallbackRecord: record,
  );
  if (ok) {
    history.replaceRecordImmediate(historyRecordWithEndTime(record, end));
  } else {
    ref.showApiToast('同步失败，稍后请重试');
  }
  return ok;
}
