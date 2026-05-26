## ADDED Requirements

### Requirement: Trends center uses custom start and end dates

The system SHALL let users select a local start date and end date for the trends chart instead of fixed preset ranges (today/week/month/quarter).

趋势中心 MUST 以**开始日、结束日**（本地自然日）作为查询条件，MUST NOT 再以「今日/周/月/季」分段按钮作为唯一时间选择方式。

#### Scenario: Open date range picker

- **WHEN** 用户点击「选择时段范围」胶囊
- **THEN** 系统 MUST 提供日期范围选择并更新展示的 `MM-dd — MM-dd` 文案

#### Scenario: Reload chart after range change

- **WHEN** 用户确认新的起止日期且校验通过
- **THEN** 系统 MUST 按新区间重新请求 piece 并刷新量柱图

### Requirement: Date span is limited to 30 calendar days

The system SHALL reject or block trend queries when the inclusive calendar-day span exceeds 30 days.

起止日期（**含首尾两日**）的日历日数 MUST **≤ 30**；超出时 MUST 提示用户且 MUST NOT 发起查询、MUST NOT 持久化该非法范围。

#### Scenario: Span within limit

- **WHEN** 用户选择 2026-05-01 至 2026-05-30
- **THEN** 系统 MUST 允许查询并展示柱图

#### Scenario: Span exceeds limit

- **WHEN** 用户选择的跨度大于 30 个日历日
- **THEN** 系统 MUST 提示跨度不可超过 30 天，并保持此前有效范围与图表不变

### Requirement: Trends date range is remembered

The system SHALL persist the last valid start and end dates and restore them on the next visit to the trends center.

用户确认且校验通过的起止日期 MUST 写入本地持久化；下次进入趋势中心 MUST 优先恢复该范围（合法且 ≤30 天）。

#### Scenario: Restore on return

- **WHEN** 用户曾选择 2026-05-10 至 2026-05-20 并离开趋势页后再次进入
- **THEN** 时段胶囊 MUST 显示该区间，且柱图 MUST 按该区间加载

#### Scenario: Invalid memory fallback

- **WHEN** 持久化数据缺失、不可解析或跨度超过 30 天
- **THEN** 系统 MUST 使用默认范围（本周一至今天，本地）并正常加载柱图

### Requirement: Trends layout matches reference structure with app theme

The system SHALL present dual glass capsules for event and date range and a fixed chart title inside the glass panel.

顶栏 MUST 为左右两枚玻璃质感胶囊（左：事件；右：时段范围）。图表玻璃区内 MUST 固定显示居中标题 **「喂养趋势图」**（不随事件名变化）。视觉 MUST 使用主页事件 **accent** 与深色玻璃面板，MUST NOT 采用与主页冲突的独立浅色 clay 主题。

#### Scenario: Fixed chart title

- **WHEN** 用户选中任意事件并展示图表
- **THEN** 图表区标题文案 MUST 为「喂养趋势图」

#### Scenario: Themed glass bar columns

- **WHEN** 柱图有数据
- **THEN** 柱体 MUST 使用当前事件 accent 的单色渐变（非多色随机），并 MUST 为圆角柱形

### Requirement: Bucket mode follows date span

The system SHALL bucket trend points by hour for a single-day span and by calendar day for multi-day spans within the selected range.

当开始日与结束日为**同一天**时，横轴 MUST 按**小时**分桶；跨多时 MUST 按**自然日**分桶。轴标签抽稀 MUST 沿用 `ChartAxisGranularity`（竖屏 X5/Y3，横屏 X7/Y5）。

#### Scenario: Single day hourly

- **WHEN** 起止日期均为今天
- **THEN** 柱图横轴 MUST 为小时粒度（整点标签抽稀）

#### Scenario: Multi day daily

- **WHEN** 起止日期跨至少两个自然日且跨度 ≤30 天
- **THEN** 柱图横轴 MUST 为按日分桶（日期标签均匀抽稀）
