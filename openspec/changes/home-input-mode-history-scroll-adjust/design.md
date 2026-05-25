## Context

- **布局**：`HomeScreen` 主体为 `Column`：`HomeTodaySummaryPanel` + `Expanded(HomeHistoryScroll)` + `AnimatedContainer(height: _bottomInputPanelHeight)`。底部高度随 `HomeInputChannel` 变化（voice 148、text 220、buttons `kHomeButtonInputPanelHeight` ≈ 76）。
- **滚动**：`HomeHistoryScroll` 使用 `ScrollController`，默认 `_followLatest = true`；用户上滑超过 `followBottomThreshold`（96px）时 `_followLatest = false`，并显示「回到底部」按钮。
- **问题根因**：模式切换只改 `AnimatedContainer.height`，历史区 `Expanded` 高度随之变化，`maxScrollExtent` 改变，但 `pixels` 不变 → 原先在底部的内容相对新视口不再贴底。
- **典型复现**：文字/按钮模式（底部较高）停在底部看最新 → 切到语音球（底部变矮、历史区变高）→ 最新记录需手动下滚。

## Goals / Non-Goals

**Goals:**

- 模式切换完成后，**跟底用户**自动看到最新记录，无需手动滚动。
- 与 220ms 面板动画协调，避免滚底时 layout 未稳定。
- 冷启动恢复输入模式时，若列表已跟底，同样重锚。

**Non-Goals:**

- 修改三种模式的底部高度数值或 `AnimatedContainer` 时长。
- 改变用户非跟底时的滚动位置（不强制滚底）。
- Web 仅文字模式、无切换器场景（无切换则无补偿，行为不变）。

## Decisions

### 1. 何时触发重锚

在 `_selectInputChannel`（及 `_restoreSavedInputChannel` 切到 voice 的路径）完成 `setState` 后，调用：

```text
_scheduleHistoryReanchorAfterInputModeChange()
```

条件（满足其一即滚底）：

| 条件 | 行为 |
|------|------|
| `HomeHistoryScrollState.followLatest == true` | `scrollToBottom(force: true)` |
| 距底部 ≤ `followBottomThreshold`（96px） | 同上，并恢复 `_followLatest = true` |

若 `_followLatest == false` 且距底部 > 阈值：**不滚动**。

### 2. 与 AnimatedContainer 时序

```text
setState(切换 channel)
  → AnimatedContainer 220ms 插值改变高度
  → post-frame #1（布局后）
  → post-frame #2（maxScrollExtent 稳定后，可选）
  → scrollToBottom(force: true, animate: 与 disableAnimations 相反)
```

- 首次 post-frame 在 `WidgetsBinding.instance.addPostFrameCallback`。
- 若 `maxScrollExtent` 仍变化，复用 `HomeHistoryScroll.scrollToBottom` 内已有二次 post-frame 逻辑。
- 动画：跟随时长与面板一致 `220ms` + `Curves.easeOutCubic`（与 `AnimatedContainer` 相同）；`MediaQuery.disableAnimationsOf` 时 `jumpTo`。

### 3. API 形态

在 `HomeHistoryScrollState` 新增：

```dart
void reanchorAfterViewportChange({bool animate = true})
```

内部：若跟底或近底则 `scrollToBottom(force: true, animate: animate)`；否则 no-op。

`HomeScreen` 通过 `_historyScrollKey.currentState?.reanchorAfterViewportChange(...)` 调用。

### 4. 触发点汇总

| 入口 | 是否触发 |
|------|----------|
| `HomeInputModeDock.onChannelSelected` → `_selectInputChannel` | ✓ |
| `_restoreSavedInputChannel` 切 voice（async） | ✓（setState 后同样调度） |
| `_restoreSavedInputChannel` 非 voice 仅 setState | ✓ |
| 同 channel 重复选择 | ✗（early return） |

### 5. 空列表 / 加载中

历史为空或仅 loading 占位：调用 no-op（`scrollToBottom` 已有 hasClients 守卫）。

## Risks / Trade-offs

- **[Risk] 双 post-frame 仍早于 extent 稳定** → 沿用 `scrollToBottom` 双帧 + 可选短 delay 一帧；fly 动画进行中不额外滚底（`flyAnimationInProgress` 时可跳过或 defer）。
- **[Trade-off] 近底阈值与跟底判定** → 复用 96px 阈值，与现有跟底 UX 一致。

## Migration Plan

- 纯客户端；手工验证 voice ↔ text ↔ buttons 循环切换、跟底/非跟底两种状态。

## Open Questions

- （默认）fly 动画进行中切换模式极少见，首版不特殊处理；若冲突再 defer。
