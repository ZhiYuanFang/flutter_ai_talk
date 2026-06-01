## ADDED Requirements

### Requirement: 今日事件 chip 可打开趋势 Sheet

The system SHALL open a glass-style bottom sheet when the user taps an event chip in the home today summary panel. 用户点击主页「今日」总结区中某一事件的 chip 时，系统 MUST 从底部弹出玻璃态 Sheet，展示该事件的小时趋势。

#### Scenario: 点击 chip 打开 Sheet

- **WHEN** 用户点击今日总结中某事件 chip
- **THEN** 系统 MUST 展示包含该事件名称/图标与趋势图的玻璃态 Sheet

#### Scenario: 无今日总额的事件不出现

- **WHEN** 某事件不在 `aggregateTodayTotals` 结果中
- **THEN** 该事件 MUST NOT 出现在今日 chip 列表中（既有行为，本变更不新增无 chip 入口）

### Requirement: 双折线仅展示今昨两日

The system SHALL display exactly two line series in the sheet: today and yesterday for the selected event. Sheet 内 MUST 仅包含**今日**与**昨日**两条折线，不得展示周/月/季区间，且 MUST NOT 展示柱图。

#### Scenario: 今日与昨日曲线

- **WHEN** Sheet 已加载数据
- **THEN** 用户 MUST 能区分「今日」「昨日」两条折线（图例或标签），且图中 MUST NOT 包含 BarChart

### Requirement: 横轴固定 0 点至 24 点且标签数随方向变化

The system SHALL use a fixed 24-hour local-day axis from 00:00 through 24:00 with 24 data buckets, and SHALL show evenly distributed time labels per orientation. 横轴 MUST 表示本地自然日 **0:00–24:00**，数据为 **24** 个整点桶。底部时间文案 MUST 均匀分布：**竖屏 5 个**、**横屏 7 个**（文案数量，非仅 5/7 个数据点）。

#### Scenario: 竖屏横轴五档文案

- **WHEN** 设备为竖屏且 Sheet 展示图表
- **THEN** 横轴 MUST 显示 5 个均匀分布的时间文案（如 0:00、6:00、12:00、18:00、24:00 或等效五档）

#### Scenario: 横屏横轴七档文案

- **WHEN** 设备为横屏且 Sheet 展示图表
- **THEN** 横轴 MUST 显示 7 个均匀分布的时间文案

### Requirement: 纵轴按今昨最大值缩放且刻度数随方向变化

The system SHALL scale the vertical axis from zero to slightly above the maximum bucket value across both days. 纵轴 MUST 从 0 起算，上限 MUST 基于今日与昨日 24 桶中的**最大值**（建议 ×1.15 留白）。刻度文案数量：**竖屏 3 个**、**横屏 5 个**。

#### Scenario: 两日峰值决定纵轴

- **WHEN** 今日某小时值为 3、昨日某小时值为 5
- **THEN** 纵轴上限 MUST 能容纳至少 5（含留白），且两日曲线均完整可见

### Requirement: 玻璃态视觉与固定浅色文字

The system SHALL present the sheet using the same glass panel visual language as the history edit sheet with fixed light foreground text. Sheet MUST 使用 `HistoryEditGlassPanel`（或等价玻璃容器），背景为事件色暗色渐变；图表轴、标题、图例文字 MUST 使用固定浅色前景，不得因 shell 浅色主题而变为深色字。

#### Scenario: 与历史编辑 Sheet 风格一致

- **WHEN** 用户打开趋势 Sheet
- **THEN** 面板 MUST 呈现磨砂玻璃、圆角与浅色文字，与历史编辑 Sheet 视觉一致

### Requirement: 无数据时仍绘制零值折线

The system SHALL render flat zero lines when there is no qualifying data rather than hiding the chart. 当今/昨均无符合条件记录时，系统 MUST 仍绘制 **24 个值为 0** 的数据点所形成的平线，MUST NOT 用「暂无数据」替代整个图表区域。

#### Scenario: 两日皆无记录

- **WHEN** 本地与 API 均无计入记录
- **THEN** 今日与昨日折线 MUST 均在 y=0 处显示，图表区域仍可见
