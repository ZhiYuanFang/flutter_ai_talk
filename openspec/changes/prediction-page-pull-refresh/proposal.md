## Why

智能预测页目前只能靠进页 ensure、WS/home 失效与 App resume 刷新数据；用户看到卡片过期时没有主动对齐入口。喂养历史与消息 Tab 已有下拉刷新，预测页应对齐同一交互预期。

## What Changes

- 预测页（竖屏与横屏卡片区）增加 **顶部下拉刷新**（`RefreshIndicator`）；空态/短列表也须可拉。
- 一次下拉刷新范围：**home 历史第 1 页**（`refreshFromRemote` 或等价）+ **预测 7 日 range**（`ensureLoaded(force: true)` 或等价）；**不**整包 resume（不含 care-alert / UCG unread 等）。
- 下拉开始时 **重置** prediction range 的连续失败熔断计数，使本次及后续自动 ensure 不再被「已熔断」挡住。
- home 或 range **任一路失败** → `showAppToast`（error tone）提示刷新失败；成功则静默结束指示器。
- **不做**底部上拉刷新；**不**在下拉路径直接触发 imminent / active-ETA pending PUT（仍走既有指纹派生）。
- 一手势对上述两路 HTTP 各最多主动一轮（遵守既有 single-flight）；不新建平行拉取栈。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：增加用户下拉刷新交互、失败 Toast、刷新范围（home 第 1 页 + range）、禁止底部上拉。
- `prediction-range-history`：用户显式重试（预测页下拉）MUST 重置会话内 range 连续失败熔断计数后再 force 拉取。

## Impact

- UI：`app/lib/ui/smart_prediction_screen.dart`（`buildCardsBody` / list / waterfall / 空态包裹 `RefreshIndicator` + `AlwaysScrollableScrollPhysics`）。
- Providers：`prediction_range_history_provider.dart`（熔断重置 + 可观测失败结果）；`home_history_notifier.dart`（复用 `refreshFromRemote`，必要时暴露失败信号供 Toast）。
- 无新 HTTP 端点、无 Android 原生/R8 变更、无新 WebSocket。
- 与 resume bundle、WS `scheduleInvalidation` 并存；下拉不得绕过副作用 HTTP 治理。
