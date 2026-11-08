## Why

兄弟仓 `go_ai_talk` 的 `live-activity-update-ack-timeout` 已在 APNs Live Activity **`event=update`** 的 ContentState 中注入临时 `ack`，并在短超时未收到客户端回执时删除 `activity` token、改走同机 `push_to_start` `start`，用于探测「用户划掉锁屏后 update 仍假成功」。本仓尚未解码/回传该字段，联调后会反复误触发 restart。需要 iOS **原生层**在收到带 `ack` 的 ContentState 后立即免鉴权回执。

## What Changes

- **ContentState 契约对齐**：统一 `BabyLiveActivityAttributes.ContentState` 增加可选 `ack`（与 `phase` / `items` 并列，随 update 消息体一并发来；UI 忽略该字段）。
- **原生即时回执**：主 App Runner 在 ActivityKit 交付/更新 ContentState 且 `ack` 非空时，立即 `POST /app/api/push/live-activity/ack`（body：`wxId` / `deviceKey` / `ack`），复用既有 register 免鉴权上下文；**不得**经 Flutter/Dart 补传。
- **文档**：`LIVE_ACTIVITY.md` 补充 `ack` 字段与 ack HTTP 契约，对齐 Go twin。
- **非目标**：不改锁屏/Island 列表 UI；不改 register；不改 Go 超时/failover；不做设置页 ack 诊断；不在 Widget Extension 内发 ack。

## Capabilities

### New Capabilities

- `live-activity-update-ack`：从统一 ContentState 读取 `ack`，并在原生层免 Bearer 回执 `POST /app/api/push/live-activity/ack` 的客户端行为。

### Modified Capabilities

- （无）基线 `predict-imminent-live-activity` / `predict-timing-live-activity` / `settings-live-activity` 的展示与 register 需求不变；本变更叠加在统一 Attributes（`unify-live-activity-list` / `BabyLiveActivityAttributes`）之上。

## Impact

- iOS：`PredictLiveActivityAttributes`（ContentState.`ack`）、`PredictLiveActivityBridge`（观察 content 更新）、`LiveActivityNativeRegister` 同族原生 HTTP（ack POST）或并列 ack helper。
- 文档：`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`。
- Dart：无强制改动（明确禁止 Dart 补传 ack）。
- 对端：依赖已落地的 Go `live-activity-update-ack-timeout`（`LIVE_ACTIVITY_ACK_TIMEOUT_MS` 默认 3000）；依赖统一单条 LA（`unify-live-activity-list`）同发或已合入。
- 基线：相对 `openspec/specs/v2.1.8.md` 为新增送达回执行为，不破坏既有锁屏样式需求。
