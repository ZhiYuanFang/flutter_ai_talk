## MODIFIED Requirements

### Requirement: 紧凑时间轴行布局

The client SHALL render each history row as a compact timeline tile with a left dot column, event logo, time label, event name, and optional trailing text, within a fixed row height suitable for dense lists. 主页历史 **必须** 以固定行高的紧凑时间轴行展示；**时分（HH:mm）必须位于圆点列之前**，其后为圆点、事件 logo、事件名与可选尾注；行高与 `HomeHistoryTimelineTile.rowHeight` 一致（**该事件在列表内最新一条**、**非进行中计时**且展示相对时间标签时允许额外高度，同屏可有多行增高）。

#### Scenario: 行内字段顺序

- **WHEN** 渲染一条历史记录行
- **THEN** 从左至右顺序 MUST 为：`HH:mm` → 圆点 → logo → 事件名 →（可选）尾注

#### Scenario: 行高与圆点列

- **WHEN** 渲染历史行
- **THEN** 圆点列中心 x 坐标 MUST 与同日块内渐变连线绘制共用更新后的布局常量（含时分列宽度）

#### Scenario: 日块内多条记录

- **WHEN** 同一日历日卡片内有多条记录
- **THEN** 除各行圆点外，MUST 满足 `home-history-day-timeline-links` 中连线样式要求
