## Why

预测临近与进行中计时需要在 iOS 锁屏以 Live Activity 呈现；服务端起停、限流与清场由兄弟仓 `go_ai_talk` change **`predict-live-activity-push`** 负责。本变更只覆盖 Flutter/iOS 客户端：两类锁屏组件、Push to Start token、等推送展示与点击进预测页。

## What Changes

- **两类 Live Activity（客户端）**：Imminent（即将发生：logo + 文案 + 右箭头）与 Timing（计时中：logo + 文案 + 时间 + 右箭头）分属不同 ActivityAttributes（对端 `attributesKind`=`imminent`|`timing`），**不得**共用同一组件实例表达两态。
- **仅等推送**：本机 MUST NOT 用 `Activity.request`（或等价）自行拉起 Imminent/Timing；展示依赖 Go 下发的 Push to Start / liveactivity。
- **LA token 上报**：MUST 调用对端已定 `POST /app/api/push/live-activity/register`（`tokenKind`=`push_to_start`|`activity`，`attributesKind`，`deviceKey`，`token`；`activity` 时带 `activityId`）。MUST NOT 把 LA token 写入既有 `POST /app/api/push/register` / `push_device` 语义。
- **点击**：打开 App 并进入预测页族表面；客户端 MUST NOT 因点击自行 dismiss Imminent（消除由 Go end 推送，见对端 change）。
- **Timing 多槽 / Imminent 单槽（展示侧）**：客户端 MUST 能同时展示多条 Timing；Imminent 以服务端 **每 wx 单槽** / pending 清场为准，客户端 MUST NOT 再实现「点开消除」。
- **Android**：**不做**锁屏 Live Activity；本变更不强制改 Android 预测通知文案。
- **桌面 WidgetKit**（`PangbaoWidget`）保持独立。
- **服务端行为不在本仓提案**：1/min、pending 清场、history Timing、iOS 取消普通预测 alert → `go_ai_talk` / `predict-live-activity-push`。

## Capabilities

### New Capabilities

- `predict-imminent-live-activity`：iOS Imminent Live Activity UI、token、深链；点开不 dismiss；引用对端推送/清场契约。
- `predict-timing-live-activity`：iOS Timing Live Activity UI；多槽；仅等推送；与 Imminent 分离。

### Modified Capabilities

- `predict-imminent-client-sync`：客户端侧明确 iOS 离线提醒消费 Live Activity 路径（token 上报与展示），pending PUT 协议不变；服务端清场/改 alert 见对端 change。

## Impact

- **Flutter / iOS**：ActivityKit Extension、capabilities/entitlements、Push to Start token 上报、深链进 `/home` 预测页；Debug 日志白名单（若新 tag）。
- **对端**：`go_ai_talk` / `openspec/changes/predict-live-activity-push`（限流、清场、LA 推送、history 钩子）。
- **基线**：`openspec/specs/v2.1.4.md` 中 `predict-imminent-client-sync` 与推送点击分流相关条款（点击进预测页行为延续）。
