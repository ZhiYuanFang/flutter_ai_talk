## Context

`HomeTipPanel` 已有 expanded 拖动、四边 docked、顶标图与 `onDraggingChanged`。问题：锁滑偏晚导致 PageView 抢手势；缺「点顶标原地折叠」。

## Goals / Non-Goals

**Goals:**

- 顶标+卡同一 pan；pointer 在 tip 上即禁 PageView。
- collapsed：点顶标缩到图标下；再点展开；位置保持当前偏移。
- 与 edge docked 并存、语义分离。

**Non-Goals:**

- 不改 tip SSE / dismiss / 新 tip 强制展开规则。
- 不恢复喂养页拉条。
- 不持久化 collapsed 跨冷启动。

## Decisions

### 1. 三态 UI：expanded | collapsed | docked

- **决策**：
  - `expanded`：卡+顶标+按钮；可拖；过半松手 → docked。
  - `collapsed`：仅胖宝圆在**当前** `_dragOffset` 位置；点圆 → expanded；拖圆可移动，松手过半仍可 → docked。
  - `docked`：半圆贴边（既有）。
- **点顶标**：仅从 expanded 进入 collapsed（动画：卡 scale/高度收到顶标锚点下）。
- **备选**：点标等同贴边 —— 已否决（explore：原地收到图标下）。

### 2. 锁 PageView：pointer down（tip + 模式球统一）

- **决策**：`Listener.onPointerDown`（命中 tip 子树）即 `onDraggingChanged(true)`；`onPointerUp/Cancel` 解锁。Pan 开始不必再重复 true。
- **决策（补）**：`HomeInputModeDock` 热区（`_hitTargetRect`）同样在 pointerDown 锁滑，不再等拖动 slop；up/cancel 解锁。点按切换模式逻辑不变。
- **备选**：仅 panStart —— 太晚（模式球现状，已否决）。

### 3. 点按 vs 拖

- **决策**：顶标用 slop（如 8–12px）：超出走拖；未超出 up → toggle collapsed。可用同一 Detector + 本地累计位移。

### 4. 折叠动画

- **决策**：`AnimationController` 将卡片 opacity/scale 收到顶标中心下方（Alignment.topCenter）；结束后隐藏卡与按钮，只留圆。展开反向播或弹性入场复用。

## Risks / Trade-offs

- [过早锁滑导致点历史失败] → 仅 tip 子树 Listener，非全屏。
- [collapsed 与 docked 混淆] → 视觉：collapsed 全圆浮空；docked 半嵌边。

## Migration Plan

- 纯 UI。回滚去掉 collapsed 与 early lock。

## Open Questions

- 无（explore 建议三句已采纳为默认）。
