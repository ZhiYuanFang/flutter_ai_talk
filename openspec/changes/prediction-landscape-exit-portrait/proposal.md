## Why

横屏投屏模式通过 `SystemChrome.setPreferredOrientations` 锁定 landscape，入口对话框仍提示「需重启应用才能退出」，用户缺少在横屏看板内一键返回竖屏的路径。右密度栏顶部是自然的退出入口，且退出后应恢复系统全方向旋转，避免长期锁竖屏或锁横屏。

## What Changes

- 横屏右密度栏（`_LandscapeColumnDensitySideRail`）**顶部**新增「返回竖屏」紧凑按钮（`Icons.stay_current_portrait` + Tooltip）。
- 点击后：先切至竖屏，再 `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` **恢复全方向**；横屏沉浸/常亮随 `isLandscape == false` 由现有 `_PredictionLandscapeImmersiveHost` 释放。
- 更新竖屏投屏入口对话框文案：移除「需重启应用才能退出」，改为提示可在横屏右栏返回竖屏。
- 抽取可复用的方向切换 helper（与投屏入口、`ucg_media_viewer` 恢复语义对齐），避免散落 magic 调用。

## Capabilities

### New Capabilities

（无独立新 capability；行为归入智能预测页。）

### Modified Capabilities

- `smart-prediction-page`：横屏右栏 MUST 提供返回竖屏控件；退出 MUST 恢复 `DeviceOrientation.values`；投屏确认文案 MUST 与可退出行为一致。

## Impact

- `app/lib/ui/smart_prediction_screen.dart`：右栏组件、投屏对话框、方向 helper 接线。
- 与并行 change `prediction-landscape-column-scale`（右三栏密度轨）互补，不重复列数/scale 逻辑。
- 无 Android 原生 / 新依赖；不涉及 WebSocket、副作用 HTTP。
