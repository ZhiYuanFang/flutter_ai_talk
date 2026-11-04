## ADDED Requirements

### Requirement: Live Activity token listening SHALL be eligible when logged in on iOS independent of message-notification preference

On iOS, when the user is logged in, the client MUST be allowed to start ActivityKit Push-to-Start / activity token listening and to POST successful tokens to `/app/api/push/live-activity/register` without requiring the application message-notification preference to be enabled. Existing automatic triggers (post-login bootstrap, resume sync paths that already call into push sync, and device-token refresh sync) MUST remain the automatic channels; this requirement MUST NOT by itself introduce additional automatic register schedules. 已登录 iOS 上，客户端 MUST 可在消息通知偏好关闭时仍监听并上报 LA token。既有自动触发通道 MUST 保持；本需求自身 MUST NOT 新增额外自动 register 日程。

#### Scenario: Logged in with message preference off still listens

- **WHEN** 已登录用户消息通知偏好为关闭且运行于支持的 iOS
- **THEN** 客户端 MUST 仍可启动 LA token 监听
- **AND** 在收到合法 token 时 MUST 仍可请求 `live-activity/register`

#### Scenario: No new automatic register channel required by settings status

- **WHEN** 交付锁屏通知显态与手动重试能力
- **THEN** 客户端 MUST NOT 仅因此新增版本号 one-shot 或其它自动 register 触发点
- **AND** 手动重试 MUST 仍走既有 listen→token→register 管线
