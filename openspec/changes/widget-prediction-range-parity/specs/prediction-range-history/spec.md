## ADDED Requirements

### Requirement: Successful range history load SHALL schedule home widget sync

After the seven-day range store successfully loads or refetches items and sets `ready` to true, the client MUST schedule a single-flight home widget sync so desktop predictions reflect the new range data. This callback MUST NOT bypass existing widget sync single-flight deduplication and MUST NOT trigger additional HTTP beyond the completed range fetch.

7 日 range 拉取或重拉成功并 ready 后，客户端 **必须** 调度 single-flight 小组件 sync，使桌面预测反映最新 range；**不得** 因此额外发起 HTTP。

#### Scenario: ensureLoaded 成功写 state

- **WHEN** `PredictionRangeHistoryNotifier` 完成 `_loadImpl` 并写入非 loading 的 ready state
- **THEN** 客户端 MUST `scheduleHomeWidgetSync`（或等价 unawaited 调用）

#### Scenario: debounce 重拉成功

- **WHEN** 历史变更经 debounce 触发 `ensureLoaded(force: true)` 并成功更新 items
- **THEN** 客户端 MUST 再次 schedule widget sync

#### Scenario: 与 range single-flight 共存

- **WHEN** 多个 consumer 同时 await 同一 range ensure Future
- **THEN** widget sync MUST 至多在 range 成功边界触发一次（或经 widget sync loop 合并连续触发）
