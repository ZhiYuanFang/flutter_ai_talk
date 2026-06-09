## Context

- `UcgHomeShell`：`PageView` page0=`HomeScreen`、page1=`UcgShell`，`PageScrollPhysics()` 支持横滑切页。
- `HomeInputModeDock`：用 `Listener` + `_tapSlop` 区分点击与拖动；拖动时更新 `_dragCenter` 并吸附/自由悬浮。
- 先例：`ucg_media_viewer.dart` 在垂直 dismiss 拖动时用 `_blockPageScroll` + `onDragActiveChanged` 临时禁用 `PageView` 翻页。

## Goals / Non-Goals

**Goals:**

- 用户拖动 dock reposition 时，不得触发 `UcgHomeShell` 的 PageView 横滑。
- 拖动结束（pointer up/cancel）后立即恢复 PageView 横滑能力。
- 不影响 dock 点击轮转、贴边半圆滑出、历史列表纵向滚动。

**Non-Goals:**

- 不改变 PageView 默认横滑进广场的产品行为。
- 不重构 dock 为 `GestureDetector` 或上移 shell 层级。
- 不处理「进入广场」拉条与 PageView 的冲突（拉条仅点击，无拖动）。

## Decisions

### 1. 拖动状态回调链

**Decision**：`HomeInputModeDock` 新增可选 `ValueChanged<bool>? onDraggingChanged`；`_isDragging` 变为 `true` 时回调 `true`，pointer up/cancel 且曾拖动时回调 `false`。`HomeScreen` 新增可选 `onDockDraggingChanged` 透传；`UcgHomeShell` 维护 `_blockPageScroll` 并传入 `HomeScreen`。

**Why**：与 `ucg_media_viewer` 模式一致；改动面最小；`HomeScreen` 仅由 `UcgHomeShell` 使用。

### 2. PageView physics 切换

**Decision**：`UcgHomeShell` 中 `PageView.physics` 为 `_blockPageScroll ? NeverScrollableScrollPhysics() : PageScrollPhysics()`。

**Why**：直接阻断横滑竞技，不依赖 `EagerGestureRecognizer` 与历史列表手势的复杂仲裁。

### 3. 不增加全屏遮罩

**Decision**：首版仅 physics 锁定，不额外铺全屏 `Listener` 遮罩。

**Why**：physics 锁定足以解决 PageView 冲突；遮罩可作为后续增强。

## Risks / Trade-offs

- [风险] 拖动过程中用户仍可用「进入广场」拉条点击切页 → 可接受，拉条为独立入口。
- [风险] `_KeepAliveHomeScreen` 需改为非 const 以传回调 → 影响极小。
