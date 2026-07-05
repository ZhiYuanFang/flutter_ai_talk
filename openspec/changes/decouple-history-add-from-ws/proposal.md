# Proposal: decouple-history-add-from-ws

## What
从按钮路径（底部按钮：time/one/number）触发的历史事件添加（`addHistoryEvent`）不再以历史 WebSocket 就绪（`isHistoryWebSocketReady`）为先决条件；保持语音/文字输入路径仍然依赖 WebSocket 就绪。

## Why
- 现状会在 WS 未就绪时延后或不发起 `add` 请求，导致乐观 `pending:*` 行长期处于“同步中…”状态，影响用户体验。
- 事件的落库（HTTP POST）与 WS 推送是两条独立通道，按钮路径应尽快提交到服务端以获得即时反馈和更短的等待。
- 该变更兼顾即时性与可靠性：在网络异常或短暂传输故障时，保留现有 `flushHistoryOutbox` 作为补偿机制（可选将失败项持久化到 outbox 以便重试）。

## Scope
- 影响：`app/lib/ui/home_screen.dart`、`app/lib/providers/home_history_notifier.dart`、`app/lib/data/remote_feed_repository.dart`、`app/lib/data/history_outbox_flusher.dart`。
- 行为变化：按钮路径立即发起 `addHistoryEvent`；语音/文字 path (`sendCommand`) 保持依赖 `isHistoryWebSocketReady`。

## Acceptance criteria
- 用户通过按钮添加事件后应立刻看到乐观行；若网络良好应在短时间内以服务端 id 替换；若业务失败应移除并显示错误提示。
- 在 transport 失败场景，应将失败项写入 `HistoryOutboxStore`（或在实现中明确为移除并记录），以便后台 `flushPendingHistoryOutbox` 重试后完成替换或提示。
- 不应引入重复插入或二次飞行动画（存在的 `historyRecordMatchesPendingAdd` / `replaceRecordId` 逻辑继续生效）。

## Risk / Mitigation
- 风险：短期内同时收到 HTTP 成功与 WS 推送造成竞态。缓解：现有的合并/替换逻辑可避免重复插行；对重复事件做幂等检查。
- 风险：UI 在 transport fail 时的可感知抖动（短暂移除 pending）。可选方案：用失败态标记代替立即移除。

---

Created-by: opsx-propose
