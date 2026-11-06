## Why

预测竖屏底部的「添加/查看桌面小组件」宽 pill FAB 长期占底并迫使列表垫高，和语音/广场已有的贴边球体系不一致。改为壳上 EdgeDock 悬浮球，可大幅减少视觉占用，并与现有贴边占位冲突解决对齐。

## What Changes

- **移除**预测页底居中 `PredictionWidgetShowcaseFab` 宽条及为其预留的列表底垫（约 96）。
- **新增**小组件贴边球（`EdgeDockShell`）：圆标 `widgets`，点按进入既有 `/widgets/showcase`；挂在 **`UcgHomeShell`**（与竖屏语音球同层），仅预测竖屏页可见时展示。
- 纳入 `EdgeDockOccupancy`（新 sticky id），与语音球、广场球互斥推开；位置可持久化。
- 可见条件对齐基线：Android/iOS、竖屏、预测 Tab 可见、已登录已绑定；横屏 / Web / 未绑定不展示。
- 球面以图标为主（peek 半圆）；「添加/查看桌面小组件」文案以 Semantics / 可选 engaged 短 caption 保留可达性，完整说明仍在 showcase 页。
- **非目标**：改 showcase 页内容与 sync；改横屏语音 chip；合并进语音/广场球菜单。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-widget-showcase`：竖屏入口由底栏宽 FAB 改为壳上 EdgeDock 贴边球；更新展示形态与挂载位置要求。

## Impact

- Flutter：`ucg_home_shell.dart`（挂球）、新 `PredictionHomeWidgetEdgeDock`（或等价）、`smart_prediction_screen.dart`（拆 FAB/底垫）、`edge_dock_occupancy.dart`（新 id）、可选 dock 位置 store。
- 复用 `EdgeDockShell` / occupancy；路由仍 `context.push('/widgets/showcase')`。
- 无新 HTTP；无 Android/iOS 原生改动；无 R8 影响。
