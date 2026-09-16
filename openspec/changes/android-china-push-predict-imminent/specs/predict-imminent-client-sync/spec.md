## ADDED Requirements

### Requirement: Client SHALL sync predict-imminent pending after local prediction updates
After the client updates locally computed prediction next-occurrence times for the active baby, it SHALL call `PUT /device/api/predict/imminent/pending` with the full list of events that have a definite `nextAt` (unix seconds), or an empty `events` array to clear server-side schedules. 本地预测更新后客户端 **必须** 全量同步预测临近待办（或空列表清空）。

#### Scenario: Sync on prediction refresh
- **WHEN** 用户已登录且本地预测列表刷新完成并含至少一条带确定 `nextAt` 的事件
- **THEN** 客户端 MUST 发起 pending 同步，body 含对应 `eventId` 与 `nextAt`（秒）

#### Scenario: Clear when no upcoming
- **WHEN** 预测刷新后没有任何可上报的确定 `nextAt`
- **THEN** 客户端 MUST 以空 `events` 同步以清空服务端闹钟

#### Scenario: Failure does not crash
- **WHEN** pending 同步 HTTP 失败
- **THEN** 客户端 MUST NOT 崩溃；MUST 记录日志；MAY 短熔断避免紧密重试

### Requirement: Predict-imminent offline delivery SHALL reuse global push registration
Offline delivery of predict-imminent notifications SHALL rely on tokens registered via `POST /app/api/push/register`; the pending sync path MUST NOT require a separate push SDK. 预测临近离线送达 **必须** 复用全局推送注册，**不得** 另接一套推送 SDK。

#### Scenario: No token still allows pending sync
- **WHEN** 设备尚未成功 register 推送 token
- **THEN** 客户端仍 MUST 允许 pending 同步；到点扇出时服务端跳过无 token 账号（既有行为）
