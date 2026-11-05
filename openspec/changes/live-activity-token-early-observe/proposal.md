## Why

App 未打开时，系统经 Push-to-Start 已在锁屏展示 Live Activity，但客户端往往拿不到、也上报不了 per-activity update token（`tokenKind=activity`）；App 前台时同一条链路正常。根因是 ActivityKit 观察挂在 Dart `startListening` 之后，且未枚举已在跑的 `Activity.activities`，系统后台唤醒窗口内来不及订 `pushTokenUpdates`。对端依赖 activity token 做 update/end 时会失败或卡住，需尽快补上「尽早订阅 + 启动补扫」。

## What Changes

- iOS 主 App **必须**在进程启动早期（`didFinishLaunching` 一带）开始 ActivityKit 观察（Push-to-Start 与 per-activity），**不得**仅等 Flutter/Dart `startListening` 才首次订阅。
- 每次开始/重订观察时 **必须**枚举当前 `Activity.activities` 并为每条订 `pushTokenUpdates`（补扫已展示、尚未上报的 LA），同时继续订 `activityUpdates` 覆盖后续新建。
- Native→Dart 投递在 channel / Dart 未就绪时 **必须**入内存 inbox（对齐 `UcgPushTapInbox` 思路），就绪后 flush；**不得**因短暂无 channel 丢弃已收到的 token。
- HTTP 仍只走 Dart `POST /app/api/push/live-activity/register`（Bearer + `deviceKey`）；原生 **不得**自行打 register。未登录时观察可继续，**不得**带无效会话上报。
- `_register` **必须**按副作用 HTTP 约定做成功身份缓存 / 去重，避免 early + 补扫导致重复 POST。
- **不**引入 channel/broadcast 替代方案；**不**恢复本地 `Activity.request`；**不**改 Go API 字段契约。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：iOS 客户端 MUST 在进程早期订阅 ActivityKit token，并对已存在 Live Activity 补扫 `pushTokenUpdates`；token 在 Dart 未就绪时可暂存，就绪且已登录后再 `live-activity/register`（含 `tokenKind=activity`）。

## Impact

- iOS：`PredictLiveActivityBridge`、`AppDelegate`（early start）、可选 token inbox。
- Flutter：`LiveActivityNative` / `LiveActivityRegistrationService`（flush、登录门闸、register 幂等缓存）；`LIVE_ACTIVITY.md`。
- 对照既有：`predict-ios-live-activity`、`live-activity-channel-retain`、`settings-live-activity-status`；基线 `openspec/specs/v2.1.4.md`。
- 无 Android/Web；无 Go twin 必改（除非联调发现无 activity token 时需服务端降级，本 change 不做）。
