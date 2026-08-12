import '../data/models.dart';
import '../providers/history_event_fly_provider.dart';
import '../providers/home_history_notifier.dart';

/// 主壳唯一 History WS → 首页历史 / 飞入管道（与喂养页 UI 解耦）。
void applyHistoryWsPayloadToHome(dynamic ref, SseHistoryPayload payload) {
  final history =
      ref.read(homeHistoryProvider.notifier) as HomeHistoryNotifier;
  final removed = payload.removedRecordId;
  if (removed != null) {
    // 删除前取元数据；无锚点时 Overlay 会放弃飞入
    HistoryRecord? existing;
    final items =
        (ref.read(homeHistoryProvider) as HomeHistoryState).items;
    for (final e in items) {
      if (e.id == removed) {
        existing = e;
        break;
      }
    }
    history.removeRecord(removed);
    requestHistoryEventFlyAfterMutation(
      ref,
      recordId: removed,
      recordForMeta: existing,
    );
    return;
  }
  final r = payload.record!;
  history.upsertRecord(r);
  // 任意 upsert：可见页门闸后请求飞入（连播接受）
  requestHistoryEventFlyAfterMutation(
    ref,
    recordId: r.id,
    recordForMeta: r,
  );
}
