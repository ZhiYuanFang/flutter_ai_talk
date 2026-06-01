## Why

主页历史列表已按日分块并展示事件色圆点，但同一日期内各条记录彼此孤立，时间轴感弱。在**同一日期**相邻记录圆点之间增加**事件色渐变连线**，可强化 chronological 视觉、与事件品牌色一致，提升列表可读性与美观度。

## What Changes

- **日块内连线**：同一 `HomeHistoryDayGroup`（同一日历日卡片）内，相邻两条历史记录左侧圆点之间绘制竖向连线。
- **渐变着色**：每条连线 MUST 从**上一条**（时间较早）事件的品牌色渐变至**下一条**（时间较晚）事件的品牌色；复用 `resolveEventColor` / 事件 catalog 配色。
- **边界规则**：**不得**跨日期卡片连线；单日仅一条记录时不绘制连线；日期吸顶 header 与卡片之间不连线。
- **与现有行布局协同**：连线位于圆点列后方（`Stack` / `CustomPaint`），不遮挡 logo、文字与行点击；与 `HomeHistoryTimelineTile.rowHeight` 对齐。
- **性能**：日块内绘制，避免全列表 `ShaderMask`；`RepaintBoundary` 按日卡片隔离（若已有则沿用）。

## Capabilities

### New Capabilities

- `home-history-day-timeline-links`：同一日期历史记录圆点间渐变连线、边界与视觉约束。

### Modified Capabilities

- `home-history-compact-timeline`（变更 `home-history-compact-timeline`）：补充日块内时间轴连线与圆点列绘制的 UI 要求（本变更 specs 中 delta 描述）。

## Impact

- `app/lib/ui/home_history_scroll.dart` — 日卡片 `Column` 改为带连线层的组合布局。
- `app/lib/ui/home_history_timeline_tile.dart` — 圆点列尺寸/锚点常量可供连线对齐（或抽取共享 metric）。
- 新增 `home_history_day_timeline_links.dart`（或等价 `CustomPainter` / 绘制组件）。
- 无网关/API 变更；无路由变更。
