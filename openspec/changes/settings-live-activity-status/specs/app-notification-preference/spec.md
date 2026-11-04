## MODIFIED Requirements

### Requirement: App SHALL persist a message-notification preference that gates push registration

The client SHALL maintain a persisted application-level preference for message notifications (default enabled). When the preference is disabled, the client MUST call push unregister (or equivalent) and MUST NOT automatically register vendor push tokens via the global push bootstrap/register path. When the preference is enabled and the user is logged in, registration MAY proceed subject to OS notification permission and existing channel/token rules. The message-notification preference MUST NOT gate iOS Live Activity token listening or `POST /app/api/push/live-activity/register`; when the preference is disabled and the user remains logged in, the client MUST still be allowed to listen for ActivityKit tokens and register them on the live-activity path. 客户端 **必须** 持久化消息通知偏好（默认开启）；偏好关闭时 **必须** 对设备推送 unregister 且 **不得** 自动 register 厂商/APNs 设备 token。消息通知偏好 **必须不得** 阻断 iOS Live Activity 监听与 `live-activity/register`；偏好关闭且仍已登录时，客户端 **必须** 仍可监听并上报 LA token。

#### Scenario: User turns preference off in settings

- **WHEN** 已登录用户在消息通知设置将总开关关闭
- **THEN** 客户端 MUST 将偏好持久化为关闭
- **AND** MUST 发起 `POST /app/api/push/unregister`（或既有 unregister 封装）
- **AND** 随后的登录态 bootstrap / sync register MUST NOT 在偏好仍关闭时成功注册新的**设备**推送 token

#### Scenario: User turns preference on with OS permission granted

- **WHEN** 用户将总开关打开且系统通知已授权且已登录
- **THEN** 客户端 MUST 允许走既有全局 push register 路径

#### Scenario: Message preference off does not stop Live Activity register

- **WHEN** 已登录用户关闭消息通知偏好且系统仍可提供 Live Activity Push-to-Start token
- **THEN** 客户端 MUST NOT 仅因消息偏好关闭而停止 LA 监听
- **AND** MUST 仍允许将 token 经 `POST /app/api/push/live-activity/register` 上报
