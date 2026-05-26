## MODIFIED Requirements

### Requirement: Trends center chart area uses glassmorphism

The system SHALL present the trends center primary chart inside a glassmorphism container consistent with history edit and home trend sheets.

当用户从主页触发趋势中心时，主图表区 MUST 使用透明/玻璃容器呈现；图表输入时间为**用户选择的起止日期**（非 `TrendRange` 四档枚举）。

#### Scenario: View trends with selected event and date range

- **WHEN** 用户已选事件且已选合法起止日期并完成加载
- **THEN** 系统 MUST 在玻璃面板内展示量柱图

#### Scenario: Dismiss without changing API contract

- **WHEN** 客户端请求趋势序列
- **THEN** 系统 MUST 仍将 `startTime`/`endTime` 作为 piece 查询参数（由起止本地日换算）

### Requirement: Trends center shows bar chart only

The system SHALL display exactly one bar chart for the selected event and date range and MUST NOT display a line trend chart on the trends center screen.

趋势中心 MUST 仅展示量柱图；MUST NOT 展示折线趋势图。

#### Scenario: Series with data

- **WHEN** 选定区间内存在数据点
- **THEN** 用户 MUST 仅看到柱图

### Requirement: Bar chart axes and metric semantics unchanged

The system SHALL preserve vertical metric semantics (hours for timer events, counts otherwise) and axis label granularity rules while using date-range-driven bucketing.

纵轴计量语义 MUST 不变；横轴标签 MUST 按小时或按日模式应用 `ChartAxisGranularity` 抽稀规则。

#### Scenario: Switch date range

- **WHEN** 用户修改起止日期并确认
- **THEN** 系统 MUST 按新边界重新分桶并刷新轴标签模式（小时或日）
