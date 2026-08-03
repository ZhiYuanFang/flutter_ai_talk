## Why

输入模式球与小贴士贴边圆各自实现拖动/半圆/锁滑，tip 贴边后难以拉出，且后续还会有更多贴边球。需要抽出与模式球对齐的**通用 EdgeDock 壳**，再让 tip 迁入，行为与模式球一致。

## What Changes

- **抽出**可复用贴边底座：参数化几何（diameter）+ `EdgeDockShell`（状态、半圆/全圆、热区外扩、点/拖 slop、向内拉累计 engage、pointerDown 锁 PageView）。
- **Phase 1**：`HomeInputModeDock` 改为壳的消费者；模式切换 / 持久化仍属模式球业务；**用户可见行为零回归**。
- **Phase 2**：tip 的 docked / collapsed（浮空圆）迁到同一壳；expanded 大卡仍由 `HomeTipPanel` 自管，过半吸附后交给壳；**贴边、点出、拉出、锁滑对齐模式球**。
- 删除 tip 内重复的半圆/弱拉出实现；geometry 从 `home_input_dock_geometry` 泛化（可保留兼容导出）。

## Capabilities

### New Capabilities

- `edge-dock-shell`：通用贴边球壳的状态、手势、热区、锁滑、半圆视觉与 engage/拉出。

### Modified Capabilities

- `home-tip-edge-dock`：tip 球态改走 EdgeDockShell；拉出/点出与模式球对齐。
- `home-tip-gesture-chrome`：锁滑经壳的 `onPointerOccupied`；浮圆不再自建一套弱手势。

## Impact

- 代码：新 `edge_dock_geometry` / `edge_dock_shell`；重构 `home_input_mode_dock.dart`、`home_tip_panel.dart`；`HomeInputDockStore` 仍只服务模式球。
- 依赖进行中 tip UI changes；本变更以模式球零回归为门禁后再迁 tip。
- 无 Android 原生。
