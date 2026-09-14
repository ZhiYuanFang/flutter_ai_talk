## REMOVED Requirements

### Requirement: Successful manual daily refresh SHALL be limited once per Shanghai day

**Reason**: 日结果幂等由 Go `CareAlertDaily` 上海日缓存保证（命中直接返回、不调智能体）；客户端 prefs「今日已刷」藏钮与 skip HTTP 与缓存重复，并阻碍冷启动回填。

**Migration**: 删除 `CareAlertManualRefreshStore` / `manualRefreshSucceededToday` / 成功后藏「AI智能分析」与成功后跳过请求；改为子页 CTA 常驻 + 文案「每日仅支持分析一次」；失败 Toast。

## MODIFIED Requirements

### Requirement: Care-alert daily fetch SHALL be manual-only from AI analysis page

The client MUST NOT invoke the care-alert daily fetch (`ensureLoaded` / repository `fetchDaily` / equivalent) from smart-prediction page entry, `UcgHomeShell` prediction-visible hooks, home-widget sync, automatic Shanghai day-rollover side effects, or **AI analysis hub entry**. The only user-facing path that MAY start a daily fetch is the **feeding workspace** 「AI智能分析」 control (plus explicit in-module retry after failure). Eligibility and feature-catalog ensure MAY still run without calling daily. 客户端 **不得** 因进入预测页、壳层可见钩子、小组件 sync、跨日副作用或 **进入 AI 分析 Hub** 自动拉取 care-alert daily；**仅** 喂养工作台「AI智能分析」（及失败重试）可发起日拉取；资格/目录 ensure **可以** 不附带 daily。

#### Scenario: 进入预测页不拉 daily

- **WHEN** 用户进入智能预测页且 session/deviceNo 门闸允许
- **THEN** 客户端 MUST NOT 因此调用 care-alert daily API

#### Scenario: 进入 AI 分析 Hub 不拉 daily

- **WHEN** 用户打开 AI 分析 Hub
- **THEN** 客户端 MUST NOT 因此调用 care-alert daily API

#### Scenario: 进入喂养工作台不自动拉 daily

- **WHEN** 用户进入喂养工作台
- **THEN** 客户端 MUST NOT 仅因进页自动调用 care-alert daily API

#### Scenario: 仅工作台手动拉取

- **WHEN** 用户在喂养工作台且已开通
- **AND** 点击「AI智能分析」
- **THEN** 客户端 MAY/MUST 发起 daily 拉取

## ADDED Requirements

### Requirement: Feeding workspace manual AI智能分析 SHALL stay available and toast on error

When care-alert is effectively unlocked (or VIP-covered) on the feeding workspace, the workspace SHALL show a control labeled 「AI智能分析」 and MUST NOT hide that control solely because a prior successful refresh occurred earlier the same Shanghai day. While the daily request is in flight, the module MUST show transitional copy 「正在思考中」 and MUST NOT allow a concurrent second daily request from that control. On business success (non-null daily payload, including empty list), the client MUST update the list and MUST NOT require persisting a client-side once-per-day success mark to hide the control. On network or business failure, the client MUST toast an error (prefer server message when present), MUST keep the 「AI智能分析」 control available for retry, and MUST NOT show a success-limited toast. Same-day idempotent results are provided by server daily cache. 喂养工作台已开通时 **必须** 展示「AI智能分析」，**不得** 仅因同日曾成功而藏钮；请求中 **必须**「正在思考中」且防并发；成功 **必须** 更新列表且 **不得** 依赖客户端一日成功标记藏钮；失败 **必须** Toast 且可重试；同日幂等由服务端日缓存保证。

#### Scenario: 点击分析

- **WHEN** 用户已开通且在喂养工作台点击「AI智能分析」
- **THEN** UI MUST 展示「正在思考中」（或等价加载态）
- **AND** 客户端 MUST 请求 `care-alert/daily`（或既有 repository 等价）

#### Scenario: 同日再次点击仍可请求

- **WHEN** 用户今日已成功获得过日列表
- **AND** 再次点击「AI智能分析」
- **THEN** 客户端 MUST 仍允许发起请求（可由服务端缓存命中快速返回）
- **AND** MUST NOT 因本地「今日已刷」标记而跳过 HTTP

#### Scenario: 失败可重试并 Toast

- **WHEN** daily 请求网络失败或业务失败
- **THEN** 「AI智能分析」MUST 仍可点击
- **AND** 客户端 MUST Toast 错误提示
- **AND** 客户端 MUST NOT 弹出成功日限类 Toast

### Requirement: Feeding analysis list SHALL open existing care-alert detail from workspace

When daily items are available on the feeding workspace, the workspace SHALL list each care-alert event item vertically. Tapping an item MUST navigate to the existing care-alert detail route with that item. 喂养工作台有日列表时 **必须** 纵向展示各项；点击 **必须** 进入既有值得留意详情路由。

#### Scenario: 点击列表项

- **WHEN** 列表展示至少一条值得留意聚合项
- **AND** 用户点击该行
- **THEN** 客户端 MUST 打开既有详情页并传入该 `CareAlertEventItem`（或等价）
