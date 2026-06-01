## Why

日历日历史卡片内记录行目前贴边展示，视觉拥挤；相对时间标签一律使用「{h}时{m}分前」，在 1 分钟内或不足 1 小时时不够自然。为日卡片增加内边距，并细化相对时间文案规则，可提升可读性与口语化体验。

## What Changes

- **日卡片内边距**：每个日历日记录背景（`DecoratedBox` 卡片）内部增加统一 **padding**，记录行与卡片圆角边缘留白，不改变卡片间外边距语义。
- **相对时间文案**（`formatHistoryRelativeAgo` / badge 展示）：
  - 与当前时刻相差 **不足 1 分钟**：显示 **「刚刚」**
  - **0 小时**且 ≥1 分钟：仅 **「{m}分前」**（不得出现 `0时`）
  - **≥1 小时**：保持 **「{h}时{m}分前」**
- UI 外层括号仍为半角 `[…]`（由 `HomeHistoryTimelineTile` 包裹，本变更不修改括号规则）。

## Capabilities

### New Capabilities

- `home-history-day-card-padding`：日历日历史记录卡片内部 padding 与布局对齐（含连线层）。

### Modified Capabilities

- `home-history-relative-ago-badge`（变更 `home-history-timeline-row-polish`）：相对时间标签文案分档规则（刚刚 / 分前 / 时+分前）。

## Impact

- `app/lib/ui/home_history_scroll.dart` — 日卡片 `Padding`、连线层与内容区对齐。
- `app/lib/data/history_line_format.dart` — `formatHistoryRelativeAgo` 分档逻辑。
- 无 API / 后端变更。
