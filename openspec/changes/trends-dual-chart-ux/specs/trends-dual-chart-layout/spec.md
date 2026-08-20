## ADDED Requirements

### Requirement: 趋势中心双图均分布局

The trends center SHALL present two chart regions for the selected event—an N-day totals chart and a selected-day detail chart—and MUST split available space evenly by orientation.

趋势中心 MUST 同时展示**近 N 日总量图**与**选中某日详图**两块区域。纵屏 MUST 上下排列且两图均分可用高度；横屏 MUST 左右排列且两图均分可用宽度。各图标题 MUST 在所属区域内横向居中，并以当前事件 accent 着色。

#### Scenario: 纵屏双图

- **WHEN** 用户在竖屏方向打开趋势中心且序列可渲染
- **THEN** 系统 MUST 以上下两块等分区域分别展示近 N 日图与某日详图

#### Scenario: 横屏双图

- **WHEN** 用户在横屏方向打开趋势中心且序列可渲染
- **THEN** 系统 MUST 以左右两块等分区域分别展示近 N 日图与某日详图，且各自标题 MUST 在该区域内居中

### Requirement: 近 N 日与某日图标题文案

The N-day chart title SHALL include the event logo, event name, and a “近 n 日总量趋势图” phrase; the day chart title SHALL show the selected calendar day with a secondary line containing the event logo, name, and “24小时内趋势图”.

近 N 日图标题 MUST 为「{事件 logo}{事件名}近 n 日总量趋势图」（n 为当前预设天数）。某日图主标题 MUST 为选中自然日的可读日期；副文案（小字）MUST 为「{事件 logo}{事件名}24小时内趋势图」。标题行与图标题内的 logo MUST 均展示（与选择行 logo 并存）。

#### Scenario: 近7日标题

- **WHEN** 当前范围为近7日且已选事件名为「喂奶」
- **THEN** 近 N 日图标题 MUST 含该事件 logo、名称「喂奶」及「近7日总量趋势图」

#### Scenario: 某日副标题

- **WHEN** 选中日为本地自然日 D
- **THEN** 某日图副文案 MUST 含事件 logo、事件名与「24小时内趋势图」

### Requirement: 选中日状态机

The trends center SHALL keep a selected local calendar day that defaults to today, MUST NOT persist it, MUST preserve it across in-page event switches, and MUST reset to today when a range change excludes it.

选中日 MUST 默认为本地「今日」且 MUST NOT 写入持久化。用户在当前页切换事件时 MUST 保持选中日不变。用户更改时间范围预设后：若选中日仍落在新区间内 MUST 保持；否则 MUST 重置为今日。用户点击近 N 日图某一柱 MUST 将选中日切换为该柱对应自然日并刷新某日详图。

#### Scenario: 换事件保持选中日

- **WHEN** 用户已选中非今日的某日 D 后在本页切换事件
- **THEN** 选中日 MUST 仍为 D，且某日详图 MUST 按新事件在 D 的数据渲染（或骨架）

#### Scenario: 换范围导致越界

- **WHEN** 选中日为 10 日前且用户将范围改为近7日
- **THEN** 选中日 MUST 重置为今日

#### Scenario: 点击柱切换日

- **WHEN** 用户点击近 N 日图中对应日期 D 的柱
- **THEN** 选中日 MUST 变为 D，且某日详图 MUST 切换为 D 的数据

### Requirement: 某日无数据展示骨架

When the selected day has no records for the current event, the day-detail region SHALL show a chart skeleton and MUST NOT show empty-state copy.

当选中日在当前事件下无可用记录时，某日详图区域 MUST 展示图表骨架（轴/轨道占位），MUST NOT 展示「暂无数据」等空态文案。该规则对今日与非今日选中日均适用。

#### Scenario: 今日无数据

- **WHEN** 选中日为今日且该事件今日无记录
- **THEN** 某日详图 MUST 为骨架且 MUST NOT 出现空态文案

#### Scenario: 历史日无数据

- **WHEN** 选中日为区间内某历史日且无记录
- **THEN** 某日详图 MUST 同样为骨架而非空态文案
