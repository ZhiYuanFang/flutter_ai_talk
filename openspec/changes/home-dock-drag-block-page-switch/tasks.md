## 1. Dock 拖动状态回调

- [x] 1.1 `HomeInputModeDock` 新增 `onDraggingChanged`，在 `_isDragging` 变为 true 及拖动结束（up/cancel）时通知

## 2. 状态透传与 PageView 锁定

- [x] 2.1 `HomeScreen` 新增 `onDockDraggingChanged` 并透传至 dock
- [x] 2.2 `UcgHomeShell` 维护 `_blockPageScroll`，拖动时 `NeverScrollableScrollPhysics()`，结束后恢复

## 3. 验证

- [x] 3.1 喂养页拖动 dock 横/纵 reposition 不触发进广场；松手后左滑仍可进广场；点击 dock 仍可轮转模式
