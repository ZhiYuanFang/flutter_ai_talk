## ADDED Requirements

### Requirement: Home widget predictions SHALL use the same history and catalog inputs as smart prediction page

When computing desktop widget predictions (`predictAllUpcoming` or equivalent), the client MUST use the same merged seven-day range history plus recall-seed pseudo-records consumed by the smart prediction page (`predictionHistoryWithRecallSeedsProvider` or equivalent), and MUST read the in-memory event catalog from the same provider as the prediction page (`eventCatalogProvider`). The client MUST NOT default widget prediction input to feeding-home pagination items (`homeHistoryProvider.items`). The client MUST exclude events whose forecast toggle is OFF using the same local disabled set as the smart prediction page (`forecastDisabledIdsProvider`).

桌面小组件计算预测时 **必须** 与智能预测页共用 7 日 range ∪ 回忆种子历史及内存 catalog；**不得** 默认使用喂养分页 items；**必须** 应用同一推演关闭集合。

#### Scenario: range 就绪后 hero 与预测页 nextAt 一致

- **WHEN** 用户已登录且 `predictionRangeHistoryProvider` 已 ready，智能预测页与小组件均已完成 sync
- **THEN** 对任一未被 skip 且推演开启的 `eventId`，小组件 hero 的 `nextAt` MUST 与预测页对应行的 `nextAt` 一致（允许 ±1s 时钟差）

#### Scenario: 不得使用喂养第 1 页深度

- **WHEN** 喂养 `homeHistoryProvider` 仅加载第 1 页而 7 日 range 含更旧记录
- **THEN** 小组件 `predictAllUpcoming` 输入 MUST 来自 range merge 历史
- **AND** MUST NOT 仅因 home 第 1 页较浅而省略影响预测的更旧样本

#### Scenario: 推演关闭事件不出现在小组件预测

- **WHEN** 用户关闭事件 A 的推演且小组件 sync 完成
- **THEN** 小组件 hero 与后续预测行 MUST NOT 以 A 作为预测展示项

#### Scenario: catalog 与预测页同源

- **WHEN** 小组件 rebuild payload 且 `eventCatalogProvider` 已 hydrate
- **THEN** 客户端 MUST 使用该 provider 的 items 解析事件名与色值
- **AND** MUST NOT 作为唯一来源仅读磁盘 catalog 而跳过内存 provider

### Requirement: Widget payload refresh SHALL trigger when seven-day range history becomes ready or changes

Flutter MUST schedule the existing single-flight home widget sync when the isolated seven-day range store transitions to ready with items, when its items change after a successful refetch, or when range invalidation completes after history mutations. Widget refresh MUST NOT be skipped solely because feeding-home `refreshFromRemote` determined `firstPageOnlyCached` with unchanged page-1 items. Scheduling MUST use explicit listen or post-success callbacks and MUST NOT start unbounded sync loops from Riverpod provider construction alone.

7 日 range 就绪或 items 变更 **必须** 触发小组件 sync；喂养 refresh 的 `firstPageOnlyCached` 早退 **不得** 单独阻止 sync；**不得** 在 provider 构造无门控自动 push。

#### Scenario: range 首次拉取完成

- **WHEN** 小组件冷启经 `ensureWidgetHistoryDepth` / range ensure 成功写入 ready items
- **THEN** 客户端 MUST 在合理延迟内调用 `scheduleHomeWidgetSync`（或等价）且 predict 行 MUST 反映 range 数据

#### Scenario: 历史变更后 range 重拉

- **WHEN** 本地历史 create/update/delete（含 WS）触发 range `scheduleInvalidation` 且重拉成功
- **THEN** 客户端 MUST 再次 schedule widget sync
- **AND** MUST NOT 仅推送喂养 home 分页快照替代 range 结果

#### Scenario: firstPageOnlyCached 仍触发 sync

- **WHEN** `homeHistoryNotifier.refreshFromRemote` 命中 `firstPageOnlyCached` 早退
- **THEN** 客户端 MUST 仍 schedule range 失效（若尚未 ready）与 widget sync
- **AND** MUST NOT 因首页第 1 页未变而跳过桌面更新 when range 可能落后
