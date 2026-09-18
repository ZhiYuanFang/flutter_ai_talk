## ADDED Requirements

### Requirement: Messages tab SHALL show UCG chat WebSocket connecting and failed states

While the user is on `UcgMessagesTab` with a logged-in bound wxId and the UCG home session is active, the client MUST show an inline status banner above the conversation list that reflects `UcgRepository` / chat `WsConnectionPhase`: **connecting** when phase is `autoReconnecting`, or `disconnected` while connection remains desired; **failed** when phase is `gaveUp`. When phase is `ready`, the banner MUST NOT show. The client MUST NOT change `ResilientWebSocketClient` retry, strike, or gaveUp policy for this requirement—UI mapping only.

已登录且 wx 已绑定、UCG 主壳会话已激活时，消息 Tab **必须**在会话列表上方展示 chat WS 连接态：连接中（`autoReconnecting`，或 desired 仍为 true 时的 `disconnected`）、连接失败（`gaveUp`）；`ready` 时 **必须 NOT** 展示横条。本需求 **不得** 修改传输层重试 / strike / gaveUp 策略。

#### Scenario: 连接中展示横条

- **WHEN** 用户在消息 Tab 且 chat WS phase 为 `autoReconnecting`
- **THEN** 客户端 MUST 展示连接中文案横条（如「正在连接…」/「正在重连…」）
- **AND** MUST NOT 因展示横条而改变 strike 或退避参数

#### Scenario: 连接失败展示横条

- **WHEN** 用户在消息 Tab 且 chat WS phase 为 `gaveUp`
- **THEN** 客户端 MUST 展示连接失败横条
- **AND** 用户点击横条 MUST 调用既有 `reconnectChatWebSocket(resetStrike: true)`（或等价 resetStrike+reconnect）
- **AND** MUST NOT 引入新的自动 SilentHeal 预算逻辑

#### Scenario: ready 隐藏横条

- **WHEN** chat WS phase 变为 `ready`
- **THEN** 消息 Tab 连接态横条 MUST 消失

#### Scenario: 未激活会话不误报

- **WHEN** 用户未登录、wx 未绑定、或 UCG 主壳会话未激活
- **THEN** 消息 Tab MUST NOT 展示「连接失败」横条误导用户
