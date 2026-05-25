## MODIFIED Requirements

### Requirement: 紧凑时间轴行布局

The client SHALL render each history row as a compact timeline tile with a left dot column, event logo, time label, event name, and optional trailing text, within a fixed row height suitable for dense lists. 主页历史 **必须** 以固定行高的紧凑时间轴行展示：左侧圆点列、事件 logo、时间、事件名与可选尾注；行高与现有 `HomeHistoryTimelineTile` 一致。

#### Scenario: 行高与圆点列

- **WHEN** 渲染历史行
- **THEN** 圆点列宽度与中心位置 MUST 与同日块内渐变连线绘制共用同一组布局常量，以保证对齐

#### Scenario: 日块内多条记录

- **WHEN** 同一日历日卡片内有多条记录
- **THEN** 除各行圆点外，MUST 满足 `home-history-day-timeline-links` 中相邻圆点渐变连线的要求
