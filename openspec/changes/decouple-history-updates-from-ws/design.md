# 设计：将更新类操作解耦出 WS 路径（HTTP 优先）

## 总览

本设计描述如何在最小风险范围内将“停止计时 / 编辑 / 更新”类操作改为 HTTP 优先执行，并保留历史 WS 用于服务器推送与语音路径。设计遵循渐进式改造原则：先改 UI 路径，再视情况调整持久化 outbox 的触发与保留策略。

## 关键变更点

1. `home_screen.dart::_stopActiveTimer`
   - 当前行为：若 record 为 pending 则本地替换；若 `!feed.isHistoryWebSocketReady` 则将更新写入持久化 outbox（`enqueueHistoryUpdateOutbox`）并立即更新 UI；否则走 `feed.updateHistoryRecord(...)`。
   - 新行为：若 record 为 pending 保持不变；若 `!feed.isHistoryWebSocketReady` **改为直接调用** `await feed.updateHistoryRecord(...)`（HTTP）；
     - 若 HTTP 成功：更新 UI（`replaceRecordImmediate`）并返回 true。
     - 若 HTTP 失败（business/transport）：回退 UI（恢复原始 record）并展示 `ref.showApiToast('同步失败，稍后请重试')`；返回 false。

2. 其他 `enqueueHistoryUpdateOutbox` 调用点
   - 扫描仓库内调用此 API 的位置（例如编辑页面 `home_history_edit_sheet.dart` 等），按与停止计时相同策略调整：优先 HTTP，失败时回退并提示。

3. `history_outbox_flusher` 与 `HistoryOutboxStore`
   - 初始阶段不移除或大幅改动持久化 outbox；保留其作为后备。后续可基于运行数据决定是否删除或更改 flush 触发条件。

## API 层契约

- `FeedRepository.updateHistoryRecord(...)` 当前已实现为通过 HTTP 更新并有 `fallbackRecord` 参数，返回 `bool`。本设计复用该契约。

## 错误处理与回退策略

- Business failure：立即回退 UI 并显示业务错误信息（如字段校验错误）。
- Transport failure（网络/超时）：回退 UI 并提示“稍后请重试”；日志记录以便后续分析。

### 额外规则（应答你的最新要求）

- 当 pending 行对应的 HTTP 请求失败（transport 或 business），应立即删除该 pending 记录并向用户展示失败提示（不保留 pending 以待重试）。

- 当持久化 outbox 的 flush 成功（即后台重试最终通过）时，应视同 HTTP 成功：在 UI 层执行相应的确认操作（如 `replaceRecordId` / `replaceRecordImmediate`），并将该记录标记为已确认；并且不要触发任何针对 optimistic 行的回滚逻辑。

- 使用 `fallbackRecord` 参数的调用（用于在更新失败时判断是否接受本地变化）在 HTTP 失败时应“老实承认”，即不要把失败当作成功处理或悄悄绕过错误；调用方应收到失败返回并据此回退 UI 或提示用户。

## 测试策略

- 单元测试：覆盖 `_stopActiveTimer` 在三种情景下的行为：pending、WS 未就绪但 HTTP 成功、WS 未就绪且 HTTP 失败。
- 集成/手动测试：在网络断开/延迟场景验证 UI 的回退和 toast 提示；验证语音路径仍要求 WS。

## 回滚计划

- 若在灰度或 QA 阶段发现回退频繁导致用户体验下降，可：
  1. 暂停改动（回退改动），恢复原持久化 outbox 路径；
  2. 或在失败场景引入本地短时缓存 + 用户可触发重试机制，降低闪烁。
