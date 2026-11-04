## Why

真机诊断出现 `ptsDeliver>0` 且 `immSeen=0`/`timSeen=0`：系统已吐 Push-to-Start token，原生 `deliver` 已计数，但 Dart 从未收到事件，因而无法 `live-activity/register`。根因是 Live Activity MethodChannel 仅以 `weak` 挂在局部变量上，ARC 回收后 Native→Dart `invokeMethod` 失败，同时超时被误标为 `partial_attributes`。必须强持有 channel 并把该指纹从「部分开通」中拆出。

## What Changes

- iOS 主 App **必须**强引用 `com.fzy.pangbao/live_activity` 的 `FlutterMethodChannel`（对齐 `ucgPushChannel`），禁止仅 `weak` + 局部 `let` 导致 Native→Dart 投递丢失。
- `deliver` **必须**仅在成功 `invokeMethod` 后计入 `pushToStartDeliverCount`；channel 为空时 **不得**当作已投递给 Dart。
- 锁屏诊断：当原生 deliver 计数 > 0 且 Dart 两类 `ptsEventSeen` 均为假时，错误类别 **必须**为独立码（如 `native_deliver_dart_miss`），**不得**展示「仅部分类型开通成功」。
- 不改 Go API、不改自动 register 触发时机、不新增 LA Off 开关。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `settings-live-activity`: Native→Dart Live Activity token 投递必须可靠；诊断须区分「原生已投、Dart 未收到」与「仅一类 attributes 成功」。
- `predict-imminent-live-activity`: iOS 客户端 MUST 将 Push-to-Start / activity token 经 MethodChannel 送达 Dart 再走 `live-activity/register`（channel 生命周期不得丢 Native 出站调用）。

## Impact

- iOS：`PredictLiveActivityBridge`、`AppDelegate`（channel 持有方式）。
- Flutter：`LiveActivityRegistrationStatus` / `_applyTimeoutDiagnosis` / 锁屏设置页人话。
- 对照 `live-activity-diagnose-status`、`settings-live-activity-status`；基线 `openspec/specs/v2.1.4.md`。
- 无 Android/Web/Go 契约变更。
