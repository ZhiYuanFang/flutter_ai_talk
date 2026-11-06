## MODIFIED Requirements

### Requirement: 点击按日 chip MUST 打开单日 TrendDayDetailChart Sheet

Tapping a per-day summary chip MUST open a glass sheet that embeds `TrendDayDetailChart` for that local calendar day and selected `eventId`, using locally held records only. 用户点击某日吸顶上某一事件 chip 时，客户端 MUST 打开玻璃态 Sheet，内嵌 **`TrendDayDetailChart`**，范围为该 chip 对应**本地自然日**与 **`eventId`**；计次 MUST 走计次时间线；计量/计时 MUST 走稀疏柱图（有数据才出柱，**X 轴** `HH:mm`、**柱顶**量值，与 `trends-center-event-charts` 一致）。Sheet 数据 MUST 由本地历史快照派生，MUST NOT 为本打开路径新增专用日详图 HTTP。客户端 MUST NOT 因此打开 `showHomeEventHourlyTrendSheet`（或等价今昨双日小时趋势 Sheet）。

#### Scenario: 点击计时事件 chip

- **WHEN** 用户点击某日某计时类事件的汇总 chip，且本地该日有该事件记录
- **THEN** Sheet MUST 出现且内含时长**柱图**（每有效样本一柱、**X 轴**时间到分、**柱顶**量值），MUST NOT 出现今昨双折线，MUST NOT 再以时长折线作为主表达

#### Scenario: 点击计量事件 chip

- **WHEN** 用户点击某日某计量（`number`）事件的汇总 chip，且本地该日有该事件记录
- **THEN** Sheet MUST 使用稀疏柱图（有数据才出柱，**X 轴**时刻到分、**柱顶**量值）

#### Scenario: 点击计次事件 chip

- **WHEN** 用户点击某日某计次（once）事件的汇总 chip
- **THEN** Sheet MUST 使用计次时间线形态的 `TrendDayDetailChart`

#### Scenario: 本地无点可画

- **WHEN** 该日该事件在本地快照中无可用绘点
- **THEN** Sheet MUST 仍打开，并遵循 `TrendDayDetailChart` 既有空态，MUST NOT 仅因此失败崩溃

## ADDED Requirements

### Requirement: 按日 Sheet 标题 MUST 为事件名与日文案同行

The feeding per-day summary chart sheet title SHALL render as one centered line: event display name, a middle-dot separator ` · `, then the day label from `formatHistoryDaySectionLabel` (or equivalent), with the day segment in a smaller type size and vertically centered with the name. The client MUST NOT use a separate full-width day-only subtitle row beneath the event name for this chrome.

喂养按日汇总图 Sheet 标题 MUST 为**居中一行**：`{事件显示名} · {日文案}`；日文案 MUST 更小且与事件名垂直居中；日文案 MUST 使用与历史日分块相同的本地日标签规则。MUST NOT 再单独用一整行仅显示日文案作为事件名下方副标题。

#### Scenario: 今日 chip 打开

- **WHEN** 用户打开某事件「今天」的按日汇总 Sheet
- **THEN** 标题区 MUST 呈现类似 `事件名 · 今天` 的单行（日文案更小），MUST NOT 在事件名正下方再独占一行「今天」
