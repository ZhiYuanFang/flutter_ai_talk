import 'active_timing_stop.dart';
import 'event_branding.dart';
import 'event_catalog_tree.dart';
import 'event_definition.dart';
import 'event_next_predictor.dart';
import 'history_line_format.dart';
import 'history_mapper.dart';
import 'models.dart';
import 'smart_prediction_rows.dart';

/// 进行中计时预计结束（同步 Go Redis / 卡片展示）。
class ActiveTimingEtaItem {
  const ActiveTimingEtaItem({
    required this.rootEventId,
    required this.leafEventId,
    required this.title,
    required this.startAt,
    required this.expectEndAt,
    this.historyId,
  });

  final int rootEventId;
  final int leafEventId;
  final String title;
  final DateTime startAt;
  final DateTime expectEndAt;
  final String? historyId;

  Map<String, dynamic> toJson() {
    final startSec = startAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final endSec = expectEndAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    return {
      'rootEventId': rootEventId,
      'leafEventId': leafEventId,
      'title': title,
      'startAt': startSec,
      'expectEndAt': endSec,
      if (historyId != null && historyId!.trim().isNotEmpty)
        'historyId': historyId!.trim(),
    };
  }

  /// 指纹片段（含秒级起止）。
  String fingerprintToken() {
    final startSec = startAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final endSec = expectEndAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    return '$rootEventId:$leafEventId:${historyId ?? ''}:$startSec:$endSec';
  }
}

/// 「预计约 HH:mm 结束」；超时追加「 · 已超时」。
String formatActiveTimingEtaLabel(DateTime expectEndAt, DateTime now) {
  final local = expectEndAt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final base = '预计约 $hh:$mm 结束';
  if (now.isAfter(expectEndAt)) {
    return '$base · 已超时';
  }
  return base;
}

/// 单条进行中 + 根历史 → ETA；duration 无把握则 null。
ActiveTimingEtaItem? buildActiveTimingEtaItem({
  required HistoryRecord active,
  required String rootEventId,
  required List<HistoryRecord> rootRecords,
  required List<EventDefinition> catalog,
  required DateTime now,
  required DateTime birthDate,
  String? rootTitle,
}) {
  if (!isActiveTimingRecord(active)) return null;
  final leafRaw = historyRecordEventId(active).trim();
  final leafId = int.tryParse(leafRaw);
  final rootId = int.tryParse(rootEventId.trim());
  // Go 保留条件要求根与叶子均为正整数
  if (leafId == null || leafId < 1 || rootId == null || rootId < 1) {
    return null;
  }
  final startAt = activeTimingStartAt(active);
  final halfLife = halfLifeDaysForBirthDate(birthDate, now);
  final durationSec = confidentDurationExpectSec(
    records: rootRecords,
    now: now,
    halfLifeDays: halfLife,
    anchorAt: startAt,
  );
  if (durationSec == null || durationSec < 1) return null;
  final expectEndAt = startAt.add(Duration(seconds: durationSec));
  if (!expectEndAt.isAfter(startAt) && expectEndAt != startAt) return null;

  final leafDef = lookupEventForRecord(catalog, active);
  final title = (rootTitle ?? leafDef?.name ?? active.eventName).trim();
  final hid = active.id.trim();
  final historyId =
      hid.isEmpty || isPendingHistoryId(hid) ? null : hid;

  return ActiveTimingEtaItem(
    rootEventId: rootId,
    leafEventId: leafId,
    title: title.isEmpty ? '未命名事件' : title,
    startAt: startAt,
    expectEndAt: expectEndAt,
    historyId: historyId,
  );
}

/// 从 home∪range 汇总各根最新进行中的 ETA 列表。
List<ActiveTimingEtaItem> buildActiveTimingEtaItems({
  required List<HistoryRecord> homeItems,
  required List<HistoryRecord> rangeItems,
  required List<EventDefinition> catalog,
  required DateTime now,
  required DateTime birthDate,
}) {
  // 合并真历史供 duration 样本（与预测管道一致）
  final byId = <String, HistoryRecord>{};
  final noId = <HistoryRecord>[];
  for (final r in [...rangeItems, ...homeItems]) {
    if (isPredictionRecallSeedRecord(r)) continue;
    final id = r.id.trim();
    if (id.isEmpty) {
      noId.add(r);
    } else {
      byId[id] = r;
    }
  }
  final merged = [...byId.values, ...noId];
  final byRoot = groupHistoryByRootEvent(history: merged, catalog: catalog);

  // 进行中以 home 优先（当前会话权威），再补 range
  final actives = <String, HistoryRecord>{};
  void consider(HistoryRecord r) {
    if (!isActiveTimingRecord(r)) return;
    final leaf = historyRecordEventId(r).trim();
    final root = leaf.isNotEmpty
        ? rootEventIdForCatalog(leaf, catalog)
        : '';
    if (root.isEmpty) return;
    final prev = actives[root];
    if (prev == null) {
      actives[root] = r;
      return;
    }
    final a = activeTimingStartAt(r);
    final b = activeTimingStartAt(prev);
    if (a.isAfter(b)) actives[root] = r;
  }

  for (final r in rangeItems) {
    consider(r);
  }
  for (final r in homeItems) {
    consider(r);
  }

  final out = <ActiveTimingEtaItem>[];
  for (final e in actives.entries) {
    final rootKey = e.key;
    List<HistoryRecord> bucket = byRoot[rootKey] ?? const [];
    if (bucket.isEmpty) {
      for (final ge in byRoot.entries) {
        if (catalogIdsEqual(ge.key, rootKey)) {
          bucket = ge.value;
          break;
        }
      }
    }
    final rootDef = lookupEventById(catalog, rootKey);
    final item = buildActiveTimingEtaItem(
      active: e.value,
      rootEventId: rootKey,
      rootRecords: bucket,
      catalog: catalog,
      now: now,
      birthDate: birthDate,
      rootTitle: rootDef?.name,
    );
    if (item != null) out.add(item);
  }
  out.sort((a, b) => a.expectEndAt.compareTo(b.expectEndAt));
  return out;
}

/// 为卡片解析某根进行中 ETA（无则 null）。
DateTime? expectEndAtForActiveTiming({
  required HistoryRecord active,
  required String rootEventId,
  required List<HistoryRecord> homeItems,
  required List<HistoryRecord> rangeItems,
  required List<EventDefinition> catalog,
  required DateTime now,
  required DateTime birthDate,
}) {
  final byRoot = groupHistoryByRootEvent(
    history: [
      for (final r in [...rangeItems, ...homeItems])
        if (!isPredictionRecallSeedRecord(r)) r,
    ],
    catalog: catalog,
  );
  List<HistoryRecord> bucket = byRoot[rootEventId] ?? const [];
  if (bucket.isEmpty) {
    for (final e in byRoot.entries) {
      if (catalogIdsEqual(e.key, rootEventId)) {
        bucket = e.value;
        break;
      }
    }
  }
  final item = buildActiveTimingEtaItem(
    active: active,
    rootEventId: rootEventId,
    rootRecords: bucket,
    catalog: catalog,
    now: now,
    birthDate: birthDate,
  );
  return item?.expectEndAt;
}
