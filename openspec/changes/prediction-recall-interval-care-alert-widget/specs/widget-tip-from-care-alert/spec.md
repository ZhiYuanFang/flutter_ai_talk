## ADDED Requirements

### Requirement: Widget tip text MUST derive from care-alert daily cache

The desktop home widget tip body MUST be derived from the client’s filtered care-alert daily list (same source as the smart prediction page marquee), not from `POST /device/history/api/chat`. Derivation MUST use each item’s non-empty `summaryLine` only; MUST NOT include `detailLines`. Multiple items MUST be joined with `\n\n` (blank line between items). When the care-alert fetch gate is not satisfied, or the daily state is not ready, the client MUST reuse the last persisted tip snapshot for the widget payload and MUST NOT clear tip prefs. When the gate is satisfied and daily state is ready but the filtered list is empty or all summaries are empty, the tip MUST be null and prefs MUST be cleared.

桌面小组件 tip 正文 **必须** 由客户端过滤后的留意日缓存列表派生（与预测页跑马灯同源），**不得** 来自 history chat。派生 **必须** 仅取非空 `summaryLine`，**不得** 拼接 `detailLines`；多项 **必须** 以 `\n\n` 空行分隔。门闸未满足或日状态未 ready 时 **必须** 复用 prefs 中上次 tip 快照推送 widget，**不得** 清空 tip prefs。门闸满足且日状态 ready 但过滤后为空或摘要皆空时 tip **必须** 为 null 且 **必须** 清除 prefs。

#### Scenario: 有留意条目则展示 tip

- **WHEN** 门闸满足且日拉取 ready 成功且过滤后至少一项且派生正文非空
- **THEN** 小组件 payload MUST 含非空 `tip.text`
- **AND** prefs MUST 写入 trim/full 快照供陪伴 inject

#### Scenario: 留意未 ready 不锁死

- **WHEN** 某次 widget sync 时留意尚未 ready
- **THEN** 本次 MUST 从 prefs 读取上次 tip 快照（若有）推送 widget
- **AND** MUST NOT 清除 prefs 或写入 fail-day 标记
- **WHEN** 留意 ready 且过滤后列表为空或摘要皆空
- **THEN** tip MUST 为 null 且 prefs MUST 清除

#### Scenario: 忽略后 tip 更新

- **WHEN** 用户忽略一条留意且过滤后列表变化
- **THEN** 后续 widget sync MUST 重算 tip 正文
- **AND** 若派生为空 MUST 清除或不再推送 tip 区块

### Requirement: Widget tip resolve MUST NOT use fail-day circuit breaker

The client MUST NOT persist or consult `widget_tip_fail_day_v1` (or equivalent) to skip tip derivation for the rest of a calendar day. Empty derivation MUST allow subsequent `scheduleHomeWidgetSync` or care-alert ensure success to retry without manual day rollover.

客户端 **不得** 持久化或读取 tip fail-day 以跳过当日剩余重试；派生为空时 **必须** 允许后续 sync 或留意 ensure 成功后再次派生，**不得** 要求跨日才重试。

#### Scenario: 先空后成功

- **WHEN** 上午 sync 时留意未 ready 导致 tip 为空
- **AND** 午后留意 ensure 成功且列表非空
- **THEN** 下一次 sync MUST 派生并写入 tip 缓存
- **AND** MUST NOT 因上午失败而跳过

### Requirement: Widget tip derivation MUST read care-alert state without provider watch in repository async paths

Tip derivation during widget sync MUST use `ProviderContainer.read` / `Ref.read` on care-alert state providers, not `Ref.watch` inside `FeedRepository` async methods. When the care-alert fetch gate is satisfied but daily state is not ready, widget sync MUST call the care-alert `ensureLoaded` path once before deriving. Care-alert HTTP MUST NOT be triggered solely by widget sync except via that explicit ensure when gate passes.

widget sync 派生 tip 时 **必须** 通过 read 读取留意 state，**不得** 在 `FeedRepository` 异步方法内 watch provider。门闸满足而日状态未 ready 时 sync **必须** 调用一次 `ensureLoaded` 后再派生。除门闸满足时的显式 ensure 外，widget sync **不得** 单独触发 care-alert HTTP。

#### Scenario: sync 不 watch

- **WHEN** `syncHomeWidgetFromRef` 派生 tip
- **THEN** 实现 MUST read 当前 `predictionCareAlertStateProvider` / 过滤列表
- **AND** MUST NOT 在 repository 回调中使用 watch

## REMOVED Requirements

### Requirement: Widget tip fetch API SHALL remain history chat sync

**Reason**: 产品改为与留意日缓存同源，避免 30s chat 与 fail-day；tip 为本地派生。

**Migration**: `fetchWidgetFeedingTip` 不再调用 `POST /device/history/api/chat`；tip 由 `deriveWidgetTipTextFromCareAlert` + sync 写入 prefs；陪伴 inject 仍读 prefs full/trim 键。

#### Scenario: 不再走 chat

- **WHEN** 客户端刷新小组件 tip
- **THEN** MUST NOT 调用 history chat 同步接口 solely for tip body
- **AND** MUST 从留意日缓存派生或跳过
