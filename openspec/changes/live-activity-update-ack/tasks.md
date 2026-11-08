## 1. ContentState 契约

- [x] 1.1 `BabyLiveActivityAttributes.ContentState` 增加可选 `ack`（`decodeIfPresent`，缺省空串）；encode/Hashable 与 UI 忽略该字段
- [x] 1.2 更新 `LIVE_ACTIVITY.md`：ContentState.`ack` 随 update 同包下发；`POST /app/api/push/live-activity/ack` 字段与免鉴权说明；明确无 Dart 补传

## 2. 原生收包与回执

- [x] 2.1 `PredictLiveActivityBridge`：对统一 Attributes 在挂 token 观察时同步挂 `contentUpdates`，并读一次当前 `content.state`；`ack` 非空则触发原生 ack
- [x] 2.2 原生 ack POST（扩展 `LiveActivityNativeRegister` 或并列 helper）：复用 wxId/deviceKey/apiBase；`POST .../live-activity/ack`；无 Bearer；同 ack 进程内去重；缺上下文/HTTP 失败仅 NSLog，不崩溃
- [x] 2.3 确认无 Dart/MethodChannel ack 补传路径；Widget Extension 不发 ack

## 3. 联调

- [ ] 3.1 与 Go `PUSH_LIVE_ACTIVITY_ENABLED` + ack 超时联调：update 带 ack → 原生回执 → 不触发 `la_ack_timeout_restart`；划掉 LA 后超时走 push_to_start restart
