## MODIFIED Requirements

### Requirement: Alert type priority SHALL be elongated interval then long active then sudden absence

When multiple candidates pass thresholds, the client SHALL retain all passing candidates (MUST NOT discard lower-priority types solely because a higher-priority type exists). Type priority **elongated interval** > **long active** > **sudden absence** MUST be used to (1) order reasons within the same event and (2) order aggregated event items across events (best type first, then highest deviation score). When no candidate passes thresholds, the candidate list MUST be empty.

多候选时客户端 **必须** 保留全部过阈值项，**不得** 因存在更高类型而丢弃较低类型。类型优先级 **必须** 用于同事件原因排序与跨事件聚合排序；无候选时列表 **必须** 为空。

#### Scenario: 两类同时保留

- **WHEN** 事件 A 触发间隔拉长且事件 B 触发进行中过久
- **THEN** 候选列表 MUST 同时包含 A 与 B
- **AND** 按事件聚合排序后 A 的条目 MUST 排在 B 之前

#### Scenario: 无候选

- **WHEN** 全部事件均未过阈值
- **THEN** 候选列表 MUST 为空

### Requirement: Care alert detail SHALL expose structured reason fields

When the user opens detail for an aggregated care-alert event item, the detail presentation SHALL list **every** firing reason for that event, each with structured fields: alert type, own-baseline metrics, age-expectation metrics (or unused), and observed metrics. The copy tone MUST use「值得留意」framing and MUST NOT claim a medical diagnosis.

打开某事件留意详情时，页面 **必须** 列出该事件全部命中原因及结构化字段；语气 **必须** 为「值得留意」，**不得** 宣称医疗诊断。

#### Scenario: 同事件多原因全量展示

- **WHEN** 事件 A 同时命中间隔拉长与进行中过久，用户打开 A 的详情
- **THEN** 详情 MUST 分别展示两条原因的结构化对比数字
- **AND** MUST NOT 使用诊断性病名恐吓文案

#### Scenario: 单原因仍结构化

- **WHEN** 用户打开仅含间隔拉长的事件详情
- **THEN** 页面 MUST 展示自身中位间隔与最近间隔（及期望上限若已使用）

## ADDED Requirements

### Requirement: Care alerts SHALL aggregate by event with one-line multi-issue summary

The client SHALL aggregate all passing care-alert candidates by `eventId` into event items. When an event has multiple firing rule types, the item’s list summary MUST mention each issue in one sentence/phrase (type labels joined in priority order). The summary line used in the marquee MUST be single-line ellipsis-friendly; full reasons MUST appear only on the detail page.

客户端 **必须** 按 `eventId` 聚合候选；同事件多规则时摘要 **必须** 一句话点出多个问题（类型标签按优先级连接）；跑马灯摘要 **必须** 适合单行省略，完整原因 **必须** 仅在详情展示。

#### Scenario: 同事件两规则一行摘要

- **WHEN** 事件「喂奶」同时命中间隔拉长与进行中过久
- **THEN** 聚合项摘要 MUST 同时包含两种类型的短标签
- **AND** 跑马灯展示该摘要时 MUST 为单行（过长则尾部省略由 UI 裁切）
