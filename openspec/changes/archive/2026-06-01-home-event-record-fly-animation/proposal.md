## Why

用户添加事件后，历史记录仅通过 WebSocket 静默插入，缺少「已记录」的即时视觉反馈。在 WS 推送到达后再播放飞行动画，可精确绑定目标 record 与列表中的 logo 锚点。用户进一步希望：**翻看旧记录时不被打断滚底**，但仍能看到图标飞向底部；并提供 **一键回到底部** 的入口。

## What Changes

- 在历史 **WebSocket/SSE 新增 record**（本地尚无该 `id`）时，触发事件图标飞行动画。
- 动画：历史区中心出现该事件 `EventLogo` → 略放大 → 缩小并飞向底部最新记录的 logo 方向/位置。
- **滚动策略 B+（修订）**：
  - 用户 **已在底部**（跟到底部）：维持现有 **滚底 + 飞入**。
  - 用户 **正在翻看旧记录**：**不自动滚底**，仍播放飞向底部目标的动画（终点为锚点 global 坐标；若锚点在视口外则飞向历史区底缘作为可见落点）。
- 翻看历史时，历史区 **正下方正中** 悬浮 **圆形** 回到底部按钮：圆内为 **向下三角形** 图标；**填充** 为 `ColorScheme.primary` 的 **0.3 透明度**，**描边** 为同主色的 **更深色调**；点击 **一键滚动到最底部**（跟到底部后隐藏）。
- `update` / `delete` / 冷启动批量同步 **不** 触发动画。
- 尊重 `MediaQuery.disableAnimations`。
- MVP 不改动 WS 协议（客户端推断 create）。

## Capabilities

### New Capabilities

- `home-event-record-fly`: 新增 record 飞行动画（触发、跟底/非跟底分支、锚点、并发）。
- `home-history-scroll-to-bottom`: 非底部时历史区底部悬浮圆形「回到底部」按钮（主色 0.3 填充 + 深主色描边 + 向下三角）。

### Modified Capabilities

（无。）

## Impact

- `app/lib/ui/home_screen.dart`：WS 监听、Overlay、跟底状态协调。
- `app/lib/ui/home_history_scroll.dart`：条件滚底（仅跟底时）、暴露 `scrollToBottom()`、跟底检测回调。
- `app/lib/ui/home_history_timeline_tile.dart`：recordId logo 锚点。
- 新建 `home_event_record_fly_overlay.dart`：飞行层。
- 新建或内联 `home_history_scroll_to_bottom_button.dart`：回底按钮。
