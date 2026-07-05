# Design: decouple-history-add-from-ws

## Summary
在按钮触发路径中立即并行发起 `addHistoryEvent`（HTTP POST）；保持乐观插入（`pending:*`）并用现有的替换/合并函数处理服务端回包。对 transport 失败，采用“混合策略”：短期内向用户反馈（移除或标记失败），并将失败项持久化到 `HistoryOutboxStore` 以便 `flushPendingHistoryOutbox` 后续重试。

## Files & Functions to change
- `app/lib/ui/home_screen.dart`
  - `_submitEventAdd()`：移除对 `feed.isHistoryWebSocketReady` 的直接 gate；在插入乐观行后立即启动 `addHistoryEvent()` 并处理 `HistoryAddPostOutcome` 三个分支（success / business / transport）。

- `app/lib/providers/home_history_notifier.dart`
  - 使用现有 `insertOptimistic`、`replaceRecordId`、`removeById`、`replaceRecordImmediate` 做状态更新。
  - 可添加 `markPendingFailed(String pendingId)`（可选）以支持 UI 显示失败态。

- `app/lib/data/remote_feed_repository.dart`
  - `addHistoryEvent()` 保持返回 `HistoryAddPostOutcome`；transport failure 要能被上层区分（已有）。

- `app/lib/data/history_outbox_flusher.dart`
  - 保持 flush 单飞；确保 `listPendingAddsInOrder()` 只列出 `pending:*`，已被替换的自然被跳过。
  - 新增（或重用）将 transport-failed add 写入 `HistoryOutboxStore` 的路径（如果选混合策略）。

## Pseudocode (button path)

```dart
// 在 _submitEventAdd after optimistic insert
unawaited(() async {
  final outcome = await feed.addHistoryEvent(body);
  if (outcome.isSuccess) {
    _markRecentlyReplaced(outcome.serverId);
    _history.replaceRecordId(pendingId, outcome.serverId);
    // schedule other post-success tasks
  } else if (outcome.isBusinessFailure || outcome.failureKind == HistoryPostFailureKind.deviceUnbound) {
    _cancelFlyAndRemovePending(pendingId);
    ref.showApiToast('保存失败: ${...}');
  } else {
    // transport failure
    // 混合策略：enqueue into outbox for retry, remove pending (或标记失败)
    await HistoryOutboxStore.enqueueAdd(deviceNo: dn, pendingId: pendingId, body: body);
    _history.removeById(pendingId); // 或 _history.markPendingFailed(pendingId)
    ref.showApiToast('网络异常，稍后重试');
  }
}());
```

## Outbox considerations
- `HistoryOutboxStore` 目前实现了 update outbox。需要新增或扩展对新增（ADD）outbox 的支持，或复用现有 update outbox 格式并区分类型。
- `flushHistoryOutbox()` 保持在 WS ready 时触发，用以补偿在按钮路径 transport 失败或其他迟发场景。

## Edge cases
- HTTP 成功且 WS 同时推送：`replaceRecordId` 与 `upsertRecord` 能避免重复行与二次动画。`_recentlyReplacedIds` 用于 suppress 再次飞行动画。
- 当设备未绑定 `deviceNo`：现有逻辑已在 `_submitEventAdd` 早期 return；保留该前置检查。

## Telemetry & Logging
- 保留并增强 `AppDebugLog.historyOutbox` 在关键分支的日志，便于排查 add/flush 的竞态与失败。

## Tests
- 单测：模拟 `feed.addHistoryEvent` 成功/业务失败/transport 失败三种情况，验证 `homeHistoryProvider` 的 items 会被正确替换/移除/入 outbox。
- 集成：离线模式下点击按钮应产生 outbox 条目；WS 恢复并 flush 后应能完成替换。

---

Created-by: opsx-propose
