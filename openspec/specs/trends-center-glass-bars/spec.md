## ADDED Requirements

### Requirement: Trends center chart area uses glassmorphism

The system SHALL render the trends center primary chart inside a glassmorphism panel aligned with history edit and home trend sheets.

趋势中心主图表区 MUST 使用玻璃拟态容器（磨砂、圆角、事件色渐变、浅色前景字），且 MUST 与 `HistoryEditGlassPanel` 或等价视觉一致。

#### Scenario: View trends with selected event

- **WHEN** 用户已选事件且序列加载完成
- **THEN** 系统 MUST 在玻璃面板内展示图表，且 MUST NOT 使用纯 Material 灰底作为唯一图表背景

#### Scenario: Loading and empty

- **WHEN** 序列加载中或当前范围无数据点
- **THEN** 系统 MUST 在图表占位区显示加载指示或空态文案，且玻璃容器结构仍可见

### Requirement: Trends center shows bar chart only

The system SHALL display exactly one bar chart for the selected event and time range and MUST NOT display a line trend chart on the trends center screen.

趋势中心 MUST 仅展示**量柱图**表达各时间桶量值；页面 MUST NOT 包含折线趋势图（`LineChart`）及独立「趋势」折线图区块。

#### Scenario: Series with data

- **WHEN** `TrendSeries` 含至少一个点
- **THEN** 用户 MUST 仅看到柱图，柱高对应该桶量值（计时类为小时、计数类为次数）

#### Scenario: No duplicate line series

- **WHEN** 用户浏览趋势中心任意时间范围
- **THEN** 系统 MUST NOT 同时展示折线与柱图两套序列

### Requirement: Bar chart axes and metric semantics unchanged

The system SHALL preserve existing horizontal range labels and vertical metric semantics for the bar chart.

量柱图 MUST 保留今日/周/月/季的横轴标签策略与纵轴计量语义（`event_number==0` 为时段小时，否则为次数）；未登录遮罩与事件切换刷新行为 MUST 与变更前一致。

#### Scenario: Switch time range

- **WHEN** 用户切换「今日 / 周 / 月 / 季」
- **THEN** 系统 MUST 重新请求并仅更新柱图数据

#### Scenario: Timer event volume

- **WHEN** 选中事件为计时类（`event_number == 0`）
- **THEN** 柱图纵轴量值 MUST 仍基于记录时段（小时），不得回退为次数语义

## MODIFIED Requirements

### Requirement: Selected event shows trend line and bar volume

**Reason**: 产品改为趋势中心仅量柱，折线移至主页今日 chip 等场景，避免重复。

**Migration**: 实现侧删除 `TrendsScreen` 内 `LineChart`；规格以 `trends-center-glass-bars` 仅柱图为准。

The system SHALL display bar volume for the selected event and time range only. The system MUST NOT display a line chart on the trends center screen.

当用户选中事件并选定时间范围后，系统 MUST 仅展示该事件的**量柱图**；MUST NOT 再展示趋势折线图。

#### Scenario: User selects an event

- **WHEN** 用户在趋势中心选中某一事件且数据加载成功
- **THEN** 系统 MUST 展示该事件在当前范围内的量柱图
