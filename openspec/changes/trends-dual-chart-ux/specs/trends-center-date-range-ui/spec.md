## MODIFIED Requirements

### Requirement: Trends center uses custom start and end dates

The system SHALL derive local start and end dates from a preset day count selected via the chart header range entry bottom sheet.

趋势中心 MUST 以预设天数推导查询起止日（结束日为本地今日，开始日为今日往前 n−1 个自然日），MUST 通过选择行右侧入口打开**底部预设 Sheet**；可选文案 MUST 仅为「近7日」「近15日」「近1个月」；UI MUST NOT 出现「近3个月」。入口位置 MUST 保持在选择行右侧（与现网一致），MUST NOT 恢复页面顶部双胶囊。

#### Scenario: Open date range picker

- **WHEN** 用户点击选择行右侧时间范围文案
- **THEN** 系统 MUST 展示含近7日/近15日/近1个月的底部 Sheet，且 MUST NOT 展示近3个月选项

#### Scenario: Reload chart after range change

- **WHEN** 用户确认新的预设范围
- **THEN** 系统 MUST 按新区间重新请求 piece 并刷新双图

### Requirement: Date span is limited to 30 calendar days

The system SHALL only offer presets whose inclusive calendar-day span is at most 30 days (7 / 15 / 30).

预设对应的含首尾日历日数 MUST 为 7、15 或 30；MUST NOT 提供超过 30 日的预设。非法或越界查询 MUST NOT 发起。

#### Scenario: Span within limit

- **WHEN** 用户选择近1个月（30 日含今日）
- **THEN** 系统 MUST 允许查询并展示近 N 日柱图

#### Scenario: No three-month option

- **WHEN** 用户打开范围预设 Sheet
- **THEN** 列表 MUST NOT 包含近3个月

### Requirement: Trends layout matches reference structure with app theme

The system SHALL present chart-header controls (event row with logo + preset range) above a dual-chart glass body using the event accent.

趋势中心 MUST 采用选择行（左：logo+事件名；右：范围预设文案）+ 双图玻璃主体；视觉 MUST 使用事件 accent 与深色玻璃面板。

#### Scenario: Header layout rendered

- **WHEN** 用户进入趋势中心并成功渲染
- **THEN** 选择行 MUST 展示左侧事件 logo+名称与右侧范围文案，且下方 MUST 为双图区域

#### Scenario: Themed glass bar columns

- **WHEN** 近 N 日柱图有数据
- **THEN** 柱体 MUST 使用当前事件 accent 的单色渐变（非多色随机），并 MUST 为圆角柱形

### Requirement: Bucket mode follows date span

The system SHALL bucket the N-day overview by local calendar day for all presets, and SHALL bucket or plot the selected-day detail on a 0–24 hour domain.

近 N 日总量图横轴 MUST 按**自然日**分桶（各预设均为跨多日）。某日详图 MUST 以该日 **0–24 时**为时间域（计时/计数为小时序列；计次为时间轴发生点）。近 N 日图与计时/计数某日图的 Y 轴刻度 MUST 固定为 **3**。

#### Scenario: N-day daily buckets

- **WHEN** 用户选择近7日/近15日/近1个月任一预设
- **THEN** 近 N 日图横轴 MUST 为按日分桶

#### Scenario: Selected day hourly domain

- **WHEN** 用户选中区间内某一自然日
- **THEN** 某日详图 MUST 按该日 0–24 时域展示（按事件类型为折线或计次时间轴）

## REMOVED Requirements

### Requirement: Trends date range is remembered

**Reason**: 产品要求每次进入默认近7日，不记住上次时间范围。

**Migration**: 停止调用 `TrendsDateRangeStore.save/loadValid`；进页使用近7日默认范围。
