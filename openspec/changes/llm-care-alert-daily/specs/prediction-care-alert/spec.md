## REMOVED Requirements

### Requirement: Care alert engine SHALL evaluate all events against dual baselines

**Reason**: 本地双基准规则引擎由服务端日缓存 LLM 列表取代；客户端不再本地评估。

**Migration**: 使用 `llm-care-alert-daily` 的日拉取 API；删除 `evaluateCareAlertCandidates` 等本地评估路径。

### Requirement: Elongated interval rule SHALL require minimum samples

**Reason**: 间隔拉长阈值规则随本地引擎删除；分析改由 Python KG+LLM 负责。

**Migration**: 服务端/Python 产出 reasons；Flutter 仅展示结构化字段。

## MODIFIED Requirements

### Requirement: Alert type priority SHALL be elongated interval then long active then sudden absence

When presenting server-provided care-alert reasons, the client SHALL retain all reasons returned for an event (MUST NOT discard lower-priority types solely because a higher-priority type exists). Type priority **elongated interval** > **long active** > **sudden absence** MUST be used to (1) order reasons within the same event and (2) order aggregated event items across events when the server does not supply an explicit order (best type first, then highest deviation score). When the server returns no items (or all are filtered out), the presented list MUST be empty.

展示服务端 reasons 时客户端 **必须** 保留同事件全部原因；类型优先级 **必须** 用于同事件/跨事件排序（服务端未给序时）；无项或过滤后为空时列表 **必须** 为空。

#### Scenario: 两类同时保留

- **WHEN** 服务端对事件 A 返回间隔拉长且对事件 B 返回进行中过久
- **THEN** 展示列表 MUST 同时包含 A 与 B
- **AND** 按事件排序后 A 的条目 MUST 排在 B 之前（在服务端未提供显式顺序时）

#### Scenario: 无候选

- **WHEN** 服务端返回空列表或过滤后为空
- **THEN** 展示列表 MUST 为空

### Requirement: Care alert detail SHALL expose structured reason fields

When the user opens detail for an aggregated care-alert event item, the detail presentation SHALL list **every** reason provided for that event, each with structured fields available from the API (alert type, own-baseline metrics, age-expectation metrics or unused, observed metrics, and optional detail lines). The copy tone MUST use「值得留意」framing and MUST NOT claim a medical diagnosis. Detail MUST expose actions **忽略** and **追问** per `llm-care-alert-daily`.

打开留意详情时 **必须** 列出该事件全部 API 原因及可得结构化字段；语气 **必须** 为「值得留意」，**不得** 宣称医疗诊断；详情 **必须** 提供忽略与追问（见 `llm-care-alert-daily`）。

#### Scenario: 同事件多原因全量展示

- **WHEN** 事件 A 含两条 reasons，用户打开 A 的详情
- **THEN** 详情 MUST 分别展示两条原因的结构化字段（有则显示）
- **AND** MUST NOT 使用诊断性病名恐吓文案

#### Scenario: 单原因仍结构化

- **WHEN** 用户打开仅含一条原因的事件详情
- **THEN** 页面 MUST 展示该原因的可得对比/说明字段

## ADDED Requirements

### Requirement: Care alerts SHALL aggregate by event with one-line multi-issue summary

The client SHALL present care-alert items as event-oriented rows for the marquee. When an event has multiple reasons, the item’s list summary MUST mention each issue in one sentence/phrase (type labels joined in priority order, or use server `summaryLine` when present). The summary line used in the marquee MUST be single-line ellipsis-friendly; full reasons MUST appear only on the detail page.

客户端 **必须** 以事件行展示留意项；多原因时摘要 **必须** 一句话点出（或使用服务端 `summaryLine`）；跑马灯 **必须** 单行友好，完整原因仅详情展示。

#### Scenario: 同事件两规则一行摘要

- **WHEN** 事件「喂奶」含间隔拉长与进行中过久两条 reasons
- **THEN** 聚合项摘要 MUST 同时体现两种类型短标签（或服务端 summaryLine 已概括）
- **AND** 跑马灯展示该摘要时 MUST 为单行（过长则尾部省略由 UI 裁切）

### Requirement: Care-alert list SHALL be server-sourced without local engine fallback

The「值得留意」data path MUST be the daily server cache API. The client MUST NOT run the legacy local dual-baseline rule engine to fill or backfill the marquee when the API is loading or failing.

「值得留意」数据路径 **必须** 为日缓存 API；加载/失败时 **不得** 用遗留本地双基准引擎填充或回退。

#### Scenario: 失败不回退引擎

- **WHEN** 日拉取失败
- **THEN** 客户端 MUST NOT 调用本地 `evaluateCareAlert*` 填充跑马灯
