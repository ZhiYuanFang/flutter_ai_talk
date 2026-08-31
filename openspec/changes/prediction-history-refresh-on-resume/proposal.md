## Why

智能预测事件卡依赖本地近 7 日 range 历史（及喂养 `homeHistory` 的进行中计时）推算；后台期间他人加记录后，用户停在预测页回前台常看不到更新，又缺少手动刷新意识。首版曾把 HTTP 刷新挂在 `HomeScreen` resume，冷启默认预测时喂养页未必 mount，刷新会漏。需迁到主壳，并一并校准值得留意与 UCG 未读。

## What Changes

- App resume 且已登录时，在 **`UcgHomeShell`**（非喂养页）编排副作用 HTTP：**MUST** 不依赖喂养页已 mount。
- 短窗去重 + single-flight 并行刷新：
  - `homeHistory.bootstrap()`（或等价）
  - `predictionRangeHistory.ensureLoaded(force: true)`
  - 值得留意 **full ensure**（`predictionCareAlert…ensureLoaded(force: true)`，内含资格再按需日列表）
  - `ucgUnreadSync`（从 `HomeScreen` **上移**到 shell）
- 历史 WS 静默自愈与 HTTP bundle **解耦**：`WS ready → return` MUST NOT 跳过 HTTP。
- 从 `HomeScreen` **移除** resume 历史刷新与 unread sync，避免双 observer 双打。
- 不因本变更在 gave-up 态自动重连历史 WS；不新建测试。
- **Non-Goals：** 预测页「广场球」入口 UI（另 change）；不恢复 tip 球。

## Capabilities

### New Capabilities

- （无；沿用本 change 既有 capability 名）

### Modified Capabilities

- `prediction-history-resume-refresh`：挂载点改主壳；resume bundle 含喂养历史、预测 range、值得留意 full ensure、UCG unread。

## Impact

- 代码：`ucg_home_shell.dart` resume；`home_screen.dart` 删历史/unread resume；既有 providers。
- 对照 `openspec/project.md` 副作用 HTTP。
- 手工：仅预测页后台回前台；喂养从未进过仍刷新；未读 count 更新。
