import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/active_timing_stop.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_mapper.dart';
import '../data/models.dart';
import '../ui/prediction_card_fly_landing.dart';
import 'event_catalog_notifier.dart';
import 'home_pager.dart';

/// 主页 PageView 当前页索引（壳层写入；飞入门闸读取）。
final homePagerIndexProvider = StateProvider<int>(
  (ref) => HomePagerPage.prediction,
);

/// 按钮 HTTP 已入列、等待 WS 触发至多一次飞入的 serverId 集合（进程内，不持久化）。
class HistoryEventFlyAwaiting {
  final Set<String> _ids = <String>{};

  /// 登记待飞 id；空串与 pending 乐观 id 忽略。
  void register(String id) {
    final t = id.trim();
    if (t.isEmpty || isPendingHistoryId(t)) return;
    _ids.add(t);
  }

  /// 是否仍在 awaiting。
  bool contains(String id) => _ids.contains(id);

  /// 一次性消费；返回清除前是否在集合中。
  bool consume(String id) => _ids.remove(id);

  /// 登出 / 切号时清空。
  void clear() => _ids.clear();
}

final historyEventFlyAwaitingProvider = Provider<HistoryEventFlyAwaiting>(
  (ref) => HistoryEventFlyAwaiting(),
);

/// upsert 前对本地列表的分类（不改表）。
enum HistoryUpsertKind {
  /// 本地无此 id，将追加。
  inserted,

  /// pending:* 行将被替换为服务端 id。
  pendingResolved,

  /// 同 id 已存在，仅合并字段。
  merged,
}

/// 根据当前 [items] 判断 [record] 的 upsert 种类。
HistoryUpsertKind classifyHistoryUpsertKind(
  List<HistoryRecord> items,
  HistoryRecord record,
) {
  if (items.any((e) => e.id == record.id)) {
    return HistoryUpsertKind.merged;
  }
  if (items.any(
    (e) =>
        isPendingHistoryId(e.id) && historyRecordMatchesPendingAdd(e, record),
  )) {
    return HistoryUpsertKind.pendingResolved;
  }
  return HistoryUpsertKind.inserted;
}

/// 一次历史落库飞入请求（可见页门闸后发出）。
@immutable
class HistoryEventFlyRequest {
  const HistoryEventFlyRequest({
    required this.session,
    required this.recordId,
    required this.rootEventId,
    required this.event,
    required this.targetPage,
  });

  final int session;
  final String recordId;
  final String rootEventId;
  final EventDefinition? event;
  /// [HomePagerPage.feeding] 或 [HomePagerPage.prediction]
  final int targetPage;
}

class HistoryEventFlyRequestNotifier
    extends Notifier<HistoryEventFlyRequest?> {
  var _session = 0;

  @override
  HistoryEventFlyRequest? build() => null;

  /// 发布新飞入；连播以最新 [session] 为准。
  void request({
    required String recordId,
    required String rootEventId,
    required EventDefinition? event,
    required int targetPage,
  }) {
    _session++;
    state = HistoryEventFlyRequest(
      session: _session,
      recordId: recordId,
      rootEventId: rootEventId,
      event: event,
      targetPage: targetPage,
    );
  }

  void clearIfSession(int session) {
    if (state?.session == session) state = null;
  }
}

final historyEventFlyRequestProvider = NotifierProvider<
    HistoryEventFlyRequestNotifier, HistoryEventFlyRequest?>(
  HistoryEventFlyRequestNotifier.new,
);

/// 预测卡 logo 锚点（长生命周期，避免 rebuild 丢 key）。
final predictionLogoAnchorRegistryProvider =
    Provider<PredictionLogoAnchorRegistry>(
  (ref) => PredictionLogoAnchorRegistry(),
);

/// History WS 判定可飞入后：仅喂养/预测可见页请求飞入（不做 isNew/awaiting 判定）。
///
/// [ref] 可为 [WidgetRef] / [Ref] / [ProviderContainer]（须支持 `.read`）。
void requestHistoryEventFlyAfterMutation(
  dynamic ref, {
  required String recordId,
  HistoryRecord? recordForMeta,
}) {
  final page = ref.read(homePagerIndexProvider);
  if (page != HomePagerPage.feeding && page != HomePagerPage.prediction) {
    return;
  }
  final catalog = ref.read(eventCatalogProvider).items;
  EventDefinition? event;
  var rootEventId = '';
  if (recordForMeta != null) {
    event = lookupEventForRecord(catalog, recordForMeta);
    final eid = historyRecordEventId(recordForMeta);
    if (eid.isNotEmpty) {
      rootEventId = rootEventIdForCatalog(eid, catalog);
    }
  }
  ref.read(historyEventFlyRequestProvider.notifier).request(
        recordId: recordId,
        rootEventId: rootEventId,
        event: event,
        targetPage: page,
      );
}
