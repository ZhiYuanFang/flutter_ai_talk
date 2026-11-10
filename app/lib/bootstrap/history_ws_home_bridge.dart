import '../data/models.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/predict_post_mutation_scheduler.dart';

/// 主壳唯一 History WS → 首页历史 / 飞入管道（与喂养页 UI 解耦）。
void applyHistoryWsPayloadToHome(dynamic ref, SseHistoryPayload payload) {
  final history =
      ref.read(homeHistoryProvider.notifier) as HomeHistoryNotifier;
  final removed = payload.removedRecordId;
  if (removed != null) {
    // 删除：更新列表，不飞入
    history.removeRecord(removed);
    return;
  }
  final r = payload.record!;
  final items =
      (ref.read(homeHistoryProvider) as HomeHistoryState).items;
  // upsert 前分类 + awaiting（一次性消费）
  final kind = classifyHistoryUpsertKind(items, r);
  final awaiting = ref.read(historyEventFlyAwaitingProvider);
  final wasAwaiting = awaiting.consume(r.id);
  final flyWorthy = wasAwaiting ||
      kind == HistoryUpsertKind.inserted ||
      kind == HistoryUpsertKind.pendingResolved;
  // 始终 upsert（含 expect*）；指纹命中仅用于跳过置脏（本路径不调度）
  acknowledgeHistoryWsExpectEcho(r);
  history.upsertRecord(r);
  // 仅新增 / awaiting：可见页门闸后请求飞入
  if (!flyWorthy) return;
  requestHistoryEventFlyAfterMutation(
    ref,
    recordId: r.id,
    recordForMeta: r,
  );
}
