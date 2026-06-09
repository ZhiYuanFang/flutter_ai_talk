## Why

`UcgHomeShell` 的 `PageView` 支持左滑进入广场，而首页 `HomeInputModeDock` 使用 `Listener` 处理拖动 reposition，二者在手势竞技场上冲突：拖动悬浮球时容易误触发页面横滑切换，影响 reposition 体验。

## What Changes

- `HomeInputModeDock` 在拖动开始/结束时向上层通知拖动状态。
- `HomeScreen` 透传拖动状态回调。
- `UcgHomeShell` 在 dock 拖动期间将 `PageView` 设为 `NeverScrollableScrollPhysics()`，拖动结束后恢复 `PageScrollPhysics()`。
- 规格补充：dock 拖动 reposition 期间不得触发喂养/广场 PageView 切换。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-input-mode-dock`：新增拖动期间不得触发外层 PageView 切换的需求。
- `ucg-home-entry`：补充 PageView 在 dock 拖动期间暂停横滑的场景。

## Impact

- `app/lib/ui/home_input_mode_dock.dart`
- `app/lib/ui/home_screen.dart`
- `app/lib/ucg/ui/ucg_home_shell.dart`
