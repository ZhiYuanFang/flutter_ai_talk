# trends-center-date-range-ui 变更规格

## MODIFIED Requirements

### Requirement: Trends center uses custom start and end dates

The system SHALL let users select a local start date and end date for the trends chart from the chart header date range entry.

趋势中心 MUST 以**开始日、结束日**（本地自然日）作为查询条件，MUST NOT 再以「今日/周/月/季」分段按钮作为唯一时间选择方式；日期范围入口位置 MUST 位于图表标题下方，而非页面顶部独立胶囊区。

#### Scenario: Open date range picker

- **WHEN** 用户点击趋势图标题下方的日期范围文本
- **THEN** 系统 MUST 提供日期范围选择并更新展示的 `MM-dd — MM-dd` 文案

#### Scenario: Reload chart after range change

- **WHEN** 用户确认新的起止日期且校验通过
- **THEN** 系统 MUST 按新区间重新请求 piece 并刷新量柱图

### Requirement: Trends date range is remembered

The system SHALL persist the last valid start and end dates and restore them on the next visit to the trends center.

用户确认且校验通过的起止日期 MUST 写入本地持久化；下次进入趋势中心 MUST 优先恢复该范围（合法且 ≤30 天），并在图表标题下方日期范围文本中展示该区间。

#### Scenario: Restore on return

- **WHEN** 用户曾选择 2026-05-10 至 2026-05-20 并离开趋势页后再次进入
- **THEN** 标题下日期范围文本 MUST 显示该区间，且柱图 MUST 按该区间加载

#### Scenario: Invalid memory fallback

- **WHEN** 持久化数据缺失、不可解析或跨度超过 30 天
- **THEN** 系统 MUST 使用默认范围（本周一至今天，本地）并正常加载柱图

### Requirement: Trends layout matches reference structure with app theme

The system SHALL present chart-header controls instead of dual top capsules while preserving app-themed glass style.

趋势中心 MUST 采用图表头部一体化布局（logo、可点击标题、可点击日期范围），MUST NOT 保留页面顶部“左事件右日期”的双胶囊控件条。视觉 MUST 使用主页事件 **accent** 与深色玻璃面板。

#### Scenario: Header layout rendered

- **WHEN** 用户进入趋势中心并成功渲染图表区域
- **THEN** 图表头部 MUST 按“logo → 标题 → 日期范围”顺序展示交互信息

#### Scenario: Themed glass bar columns

- **WHEN** 柱图有数据
- **THEN** 柱体 MUST 使用当前事件 accent 的单色渐变（非多色随机），并 MUST 为圆角柱形
