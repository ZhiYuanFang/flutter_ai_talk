## ADDED Requirements

### Requirement: `/voice/chat/ws` MUST 列为无鉴权传输例外

The App client MUST treat `/voice/chat/ws` as a documented unauthenticated voice WebSocket exception alongside `/voice/asr/ws`: it MUST NOT require a JWT `auth` first frame via `ResilientWebSocketClient`, and MUST identify the session with `deviceNo` (and PCM metadata) in a JSON `start` frame. New authenticated business channels MUST continue to use `ResilientWebSocketClient`. App 客户端 MUST 将 `/voice/chat/ws` 与 `/voice/asr/ws` 一并列为已文档化的无鉴权语音 WebSocket 例外：MUST NOT 经 `ResilientWebSocketClient` 要求 JWT `auth` 首帧；MUST 在 JSON `start` 中以 `deviceNo`（及 PCM 元数据）标识会话。新增需鉴权业务通道 MUST 继续使用 `ResilientWebSocketClient`。

#### Scenario: chat WS 不走鉴权韧性客户端模板

- **WHEN** 客户端建立预测横屏硬件对话连接 `/voice/chat/ws`
- **THEN** 连接流程 MUST NOT 发送 JWT `auth` 首帧
- **AND** MUST 在 `start` 中携带 `deviceNo` 与音频参数

#### Scenario: 历史/UCG/clinic 仍走韧性客户端

- **WHEN** 客户端连接喂养历史、UCG 聊天或胖宝诊疗 WebSocket
- **THEN** 仍 MUST 使用 `ResilientWebSocketClient`（或既有等价鉴权韧性实现）
