## ADDED Requirements

### Requirement: 日期吸顶 MUST 展示该日事件汇总 chip

The feeding home history day sticky header MUST show per-day event summary chips for the calendar day of that section, each chip with the event logo and brand color, aggregated by `eventId`. 喂养主页历史**日期吸顶行**在日期文案之外 MUST 展示**该自然日**按 **`eventId`** 聚合的汇总 chip（文案旁 logo 与品牌色）；MUST NOT 仅按易重名的 `eventName` 合并不同事件。汇总数据 MUST 来自当前主页已加载的本地历史快照中属于该日的记录。

#### Scenario: 某日有多类事件

- **WHEN** 某一日分块下本地记录含多个不同 `eventId` 的有效可聚合记录
- **THEN** 该日吸顶 MUST 分别展示各事件 chip，且视觉可区分（logo / 品牌色）

#### Scenario: 滚动到昨天

- **WHEN** 用户滚动使昨天分块成为当前吸顶日，且昨天本地快照有有效总额
- **THEN** 吸顶 MUST 显示昨天的汇总 chip（MUST NOT 仍只显示「今天」全局汇总）

### Requirement: 无有效总额时吸顶仅日期

When a day section has no qualifying aggregate totals, the sticky header MUST show only the day label and MUST NOT reserve visible height for chips. 当某日聚合结果为空时，吸顶 MUST **仅**展示日期文案，chip 区域 MUST NOT 占用可见高度（shrink 或等价）。

#### Scenario: 有记录但无总额

- **WHEN** 某日分块存在，但按日聚合 totals 为空
- **THEN** 吸顶高度 MUST 回落到日期行，MUST NOT 留出空白 chip 带

### Requirement: 吸顶高度 MUST 随 chip 折行可变

The day sticky header extent MUST vary with the laid-out height of that day’s date label plus chips (including wrap). 日期吸顶的 `minExtent`/`maxExtent`（或等价）MUST 随该日日期行 + chip 折行后的实际高度变化；MUST NOT 在有多行 chip 时裁切为固定单行日期高度。

#### Scenario: chip 折多行

- **WHEN** 某日汇总 chip 折行超过一行
- **THEN** 吸顶 MUST 完整展示日期与全部可见 chip 行（可随设计折叠策略，但不得用旧固定 ~30px 裁切）

### Requirement: 点击按日 chip MUST 打开单日 TrendDayDetailChart Sheet

Tapping a per-day summary chip MUST open a glass sheet that embeds `TrendDayDetailChart` for that local calendar day and selected `eventId`, using locally held records only. 用户点击某日吸顶上某一事件 chip 时，客户端 MUST 打开玻璃态 Sheet，内嵌 **`TrendDayDetailChart`**，范围为该 chip 对应**本地自然日**与 **`eventId`**；计次 MUST 走计次时间线，计时 MUST 走时长折线（与组件既有分支一致）。Sheet 数据 MUST 由本地历史快照派生，MUST NOT 为本打开路径新增专用日详图 HTTP。客户端 MUST NOT 因此打开 `showHomeEventHourlyTrendSheet`（或等价今昨双日小时趋势 Sheet）。

#### Scenario: 点击计时事件 chip

- **WHEN** 用户点击某日某计时类事件的汇总 chip，且本地该日有该事件记录
- **THEN** Sheet MUST 出现且内含 `TrendDayDetailChart` 时长折线（或该组件对计时的等价展示），MUST NOT 出现今昨两条小时趋势折线

#### Scenario: 点击计次事件 chip

- **WHEN** 用户点击某日某计次（once）事件的汇总 chip
- **THEN** Sheet MUST 使用计次时间线形态的 `TrendDayDetailChart`

#### Scenario: 本地无点可画

- **WHEN** 该日该事件在本地快照中无可用绘点
- **THEN** Sheet MUST 仍打开，并遵循 `TrendDayDetailChart` 既有空态（空时间线或空坐标），MUST NOT 仅因此失败崩溃

### Requirement: 打开当日汇总图 MUST 异步上报 client-usage

When the user opens the per-day summary chart sheet from a day sticky chip tap, the client MUST asynchronously report a client-usage event via the existing reporter and MUST NOT block sheet presentation on the report. 用户点击按日汇总 chip 并打开当日 `TrendDayDetailChart` Sheet 时，客户端 MUST 经既有 `clientUsageReporter`（`POST /device/app/api/client-usage/report`）上报一条稳定 `featureId`（如 `feeding_day_summary_chart_open`）与运维可读中文 `description`（可含事件显示名；MUST NOT 含 `|`）的统计日志；上报 MUST 为 fire-and-forget（如 `unawaited`），MUST NOT 等待上报完成后再展示 Sheet；上报失败 MUST 静默、MUST NOT Toast。未登录会话 MUST NOT 调用上报 API（对齐 `client-usage-report`）。仅打开 Sheet 的点击 MUST 上报；未打开 Sheet 的其它点击 MUST NOT 冒充本事件。

#### Scenario: 已登录点击 chip 打开图

- **WHEN** 用户已登录且点击某日某事件汇总 chip 成功打开单日汇总图 Sheet
- **THEN** 客户端 MUST 发起一次 client-usage 上报，且 Sheet 展示 MUST NOT 因等待该上报而延迟

#### Scenario: 上报失败不影响 Sheet

- **WHEN** 上述上报因网络或业务失败
- **THEN** Sheet MUST 仍保持已打开（或正常打开），且 MUST NOT 向用户展示上报错误提示

### Requirement: 按日汇总 MUST NOT 依赖独立今日汇总挂载位

The feeding home MUST NOT mount a standalone today-summary panel between the immersive identity header and the history list for this capability. 喂养页 MUST NOT 再在沉浸身份头与历史列表之间挂载独立「今日汇总」面板作为本能力的展示入口；按日总额 MUST 仅通过日期吸顶（及本 spec 的 Sheet）呈现。

#### Scenario: 进入喂养页

- **WHEN** 用户打开喂养页且今日有有效总额
- **THEN** 身份头正下方 MUST NOT 再出现独立今日汇总条；今日总额 MUST 出现在「今天」日期吸顶中
