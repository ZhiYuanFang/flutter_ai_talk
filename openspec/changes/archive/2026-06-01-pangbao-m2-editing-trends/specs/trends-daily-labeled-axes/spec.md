## ADDED Requirements

### Requirement: 展示「今日」趋势数据

The system SHALL provide a trend view mode (segment/tab/filter) that restricts plotted points to the **current local calendar day** for the selected event series (mock data MUST include points within today for demo).

#### Scenario: 用户选择今日

- **WHEN** 用户选择「今日」范围查看某一事件趋势
- **THEN** 图表必须仅渲染时间戳落在今日的数据点（若无点则显示空状态）

### Requirement: 横纵坐标与日期横轴

The system SHALL display visible **horizontal and vertical axes** with tick labels on the trend chart. The **horizontal axis MUST represent event dates** derived from each point’s timestamp; the vertical axis MUST represent the metric value scale.

#### Scenario: 横轴显示日期

- **WHEN** 今日范围内存在多个不同日期的点（跨日边界或时区演示数据）
- **THEN** 横轴刻度或标签必须能辨识对应日期（允许以 `MM-dd` 等短格式）

#### Scenario: 纵轴显示数值

- **WHEN** 图表渲染任意非空序列
- **THEN** 纵轴必须展示与数据范围一致的数值刻度或等效标签
