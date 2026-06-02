# api-gateway-json-keys 变更规格

基线：`openspec/specs/api-gateway-json-keys/spec.md`

## ADDED Requirements

### Requirement: 历史 WebSocket JSON 心跳帧键名

The client and gateway SHALL use JSON object frames with lowerCamelCase keys and `type` values **`ping`** / **`pong`** for history WebSocket heartbeat; no snake_case `type` aliases for heartbeat. 历史 WebSocket 心跳**必须**使用 JSON 对象帧，键名为 lowerCamelCase；心跳 **`type`** 取值**必须**为 **`ping`**（客户端发送）与 **`pong`**（服务端响应）；**不得**为心跳引入 snake_case 字段或纯文本帧。

#### Scenario: 客户端发送 ping

- **WHEN** 客户端在历史 WebSocket 上发送心跳
- **THEN** 帧内容**必须**为 JSON 对象且包含 **`"type":"ping"`**
- **AND** **不得**发送裸字符串 `ping` 或非 JSON  payload

#### Scenario: 服务端响应 pong

- **WHEN** 网关（go_ai_talk `gateway_app_history_ws.go` read loop）收到合法 JSON 且 `type` 为 `ping`（大小写按实现 trim/lower 约定）
- **THEN** 网关**必须**回复 JSON **`{"type":"pong"}`**
- **AND** 响应键名**必须**为 camelCase **`type`**，**不得**仅回复 `pong` 纯文本

#### Scenario: 客户端解析 pong

- **WHEN** 客户端收到历史 WebSocket 文本帧
- **AND** 解析为 JSON 且 `type` 为 `pong`
- **THEN** 客户端**必须**将该帧视为心跳响应
- **AND** **不得**依赖 snake_case 键（如 `message_type`）作为心跳契约
