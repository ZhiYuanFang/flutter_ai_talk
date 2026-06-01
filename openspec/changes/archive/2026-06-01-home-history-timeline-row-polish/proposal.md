## Why

主页历史时间轴行当前为「圆点 → logo → 时分 → 事件名」，时分不够贴近时间轴；连线偏粗且不透明；各事件在列表中的「最近一次」缺少「多久以前」的相对时间提示。调整行内顺序、连线样式，并为**每种已出现事件**在列表内**最新一条**记录增加相对时间标签，可提升时间轴可读性与「刚刚发生」的感知。

## What Changes

- **行内顺序**：左列 `HH:mm` 移至圆点**之前**（`时分 | 圆点 | logo | 事件名 | 尾注`）；更新 `timelineDotCenterX` 等布局常量以对齐渐变连线。
- **连线样式**：同日块内渐变连线线宽 **1px**；线段颜色在事件色渐变基础上整体 **opacity 0.7**。
- **按事件最新记录的相对时间标签**：在**当前主页历史全列表**中，对**每一种不同事件**（按事件键区分，见 design），该事件**展示时刻最新**的一条记录，在其行**下方**展示 `【{h}时{m}分前】`（相对该条展示时刻与当前时间差）；同屏可同时出现**多条**标签（每种事件至多一条）。**进行中计时**记录（`isActiveTimingRecord`，即 `eventNumber == 0` 且 `endTime` 未设置）**不得**显示该标签，即使该条为该事件在列表内的最新一条。
- **标签样式**：背景色、文字色随主题（`AppVisualTokens` / `ColorScheme`）；背景 **alpha 0.2**；字号**略小于**同行事件名。
- **刷新**：相对时间标签至少每分钟更新（与进行中计时 tick 协同或独立轻量 tick）。

## Capabilities

### New Capabilities

- `home-history-relative-ago-badge`：各事件在列表内最新一条记录下方的「xx时xx分前」标签文案、样式与刷新。

### Modified Capabilities

- `home-history-compact-timeline`（变更 `home-history-compact-timeline`）：行内字段顺序（时分在圆点前）、圆点列与连线锚点对齐。
- `home-history-day-timeline-links`（变更 `home-history-day-timeline-links`）：连线 1px、透明度 0.7。

## Impact

- `app/lib/ui/home_history_timeline_tile.dart` — 行布局、按行 `showRelativeAgo` 下方标签、布局常量。
- `app/lib/ui/home_history_day_timeline_links.dart` — 线宽与 alpha。
- `app/lib/data/history_line_format.dart` — `formatHistoryRelativeAgo`（或等价）。
- `app/lib/ui/home_history_scroll.dart` — 预计算各事件最新记录 id / `showRelativeAgo`、tick。
- `app/lib/data/event_branding.dart` — 复用 `historyRecordEventId` 与事件名回退键（与目录查找一致）。
- 无 API 变更。
