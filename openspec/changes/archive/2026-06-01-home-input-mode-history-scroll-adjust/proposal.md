## Why

首页三种输入模式（语音球 / 文字 / 按钮）底部区域高度不同（约 76–220px），切换时 `AnimatedContainer` 会改变历史列表可视高度，但 `ScrollController` 的滚动偏移不会随之重算。用户原本停在列表底部查看最新记录时，切换到语音球等模式后，最新记录常被挡在可视区外，需要手动再滚一次。

## What Changes

- 在输入模式切换且底部面板高度动画完成后，若用户处于「跟底」状态（`HomeHistoryScroll` 的 `_followLatest` 或距底部在阈值内），自动将历史列表滚回底部，使最新记录仍可见。
- 若用户已主动上滑浏览历史（非跟底），**不得**强制滚底，避免打断阅读。
- 覆盖 `HomeInputModeDock` 切换、`HomeInputChannelStore` 恢复默认模式等所有 `_inputChannel` 变更路径。
- 与既有 `AnimatedContainer`（220ms）协调：在布局稳定后触发滚底（post-frame，必要时二次 post-frame）。

## Capabilities

### New Capabilities

- `home-input-mode-history-scroll-adjust`：输入模式切换后历史列表视口变化时的跟底重锚与滚底行为。

### Modified Capabilities

- （无）不修改 add/chat、跟底检测阈值、飞行动画等既有规格语义；仅补充模式切换时的滚底补偿。

## Impact

- **UI**：`HomeScreen._selectInputChannel`（及恢复模式路径）、`HomeHistoryScroll` 或 `HomeHistoryScrollState` 新增 `reanchorAfterViewportChange` / 复用 `scrollToBottom`。
- **布局常量**：`_bottomInputPanelHeight`（voice 148 / text 220 / buttons ~76）已存在，本变更不调整高度值。
- **API / 后端**：无。
