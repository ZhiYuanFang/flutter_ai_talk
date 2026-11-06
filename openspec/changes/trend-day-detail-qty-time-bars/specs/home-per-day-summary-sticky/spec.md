## MODIFIED Requirements

### Requirement: 点击按日 chip MUST 打开单日 TrendDayDetailChart Sheet

Tapping a per-day summary chip MUST open a glass sheet that embeds `TrendDayDetailChart` for that local calendar day and selected `eventId`, using locally held records only. 用户点击某日吸顶上某一事件 chip 时，客户端 MUST 打开玻璃态 Sheet，内嵌 **`TrendDayDetailChart`**，范围为该 chip 对应**本地自然日**与 **`eventId`**；计次 MUST 走计次时间线；计量/计时 MUST 走稀疏柱图（有数据才出柱，柱标 `HH:mm`，与 `trends-center-event-charts` 一致）。Sheet 数据 MUST 由本地历史快照派生，MUST NOT 为本打开路径新增专用日详图 HTTP。客户端 MUST NOT 因此打开 `showHomeEventHourlyTrendSheet`（或等价今昨双日小时趋势 Sheet）。

#### Scenario: 点击计时事件 chip

- **WHEN** 用户点击某日某计时类事件的汇总 chip，且本地该日有该事件记录
- **THEN** Sheet MUST 出现且内含 `TrendDayDetailChart` 的时长**柱图**（每有效样本一柱、柱上时间到分），MUST NOT 出现今昨两条小时趋势折线，MUST NOT 再以时长折线作为主表达

#### Scenario: 点击计量事件 chip

- **WHEN** 用户点击某日某计量（`number`）事件的汇总 chip，且本地该日有该事件记录
- **THEN** Sheet MUST 使用稀疏柱图形态的 `TrendDayDetailChart`（有数据才出柱，柱标精确到分）

#### Scenario: 点击计次事件 chip

- **WHEN** 用户点击某日某计次（once）事件的汇总 chip
- **THEN** Sheet MUST 使用计次时间线形态的 `TrendDayDetailChart`

#### Scenario: 本地无点可画

- **WHEN** 该日该事件在本地快照中无可用绘点
- **THEN** Sheet MUST 仍打开，并遵循 `TrendDayDetailChart` 既有空态（空时间线或空柱坐标），MUST NOT 仅因此失败崩溃
