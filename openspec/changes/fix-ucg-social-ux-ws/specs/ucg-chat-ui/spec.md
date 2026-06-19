## ADDED Requirements

### Requirement: UCG chat WebSocket SHALL stay connected while logged in with bound wxId

The client MUST keep the UCG chat WebSocket `connectionDesired` true whenever the user is logged in with non-zero wxId (`isUcgWxAccountBound`), including while the user remains on feeding page 0 of `UcgHomeShell`. Transport MUST use the shared `ResilientWebSocketClient` with the same heartbeat, backoff, gave-up, token refresh, and lifecycle resume semantics as feeding history WebSocket.

已登录且 wxId 已绑定时，客户端必须保持 UCG 聊天 WebSocket 长连接（含用户停留喂养页时），传输层必须使用共享韧性客户端，机制对齐喂养历史 WS。

#### Scenario: 停留喂养页仍维持 WS

- **WHEN** 已登录用户打开 `/home` 且停留在 page 0（喂养 HomeScreen）
- **THEN** UCG 聊天 WebSocket SHALL 在 wxId 已绑定条件下尝试建连并保持 desired
- **AND** SHALL NOT 要求用户先滑入 UCG Shell

#### Scenario: 登出断开 WS

- **WHEN** 用户登出或 wxId 不再绑定
- **THEN** 客户端 SHALL 将 UCG 通道 `connectionDesired` 设为 false 并 tearDown

### Requirement: Chat send SHALL correlate optimistic rows via clientMsgId

The client MUST generate a single `clientMsgId` per outbound chat message, send it in the WebSocket `message` frame, store it on the optimistic local row, and parse `clientMsgId` from `message_delivered.message` and top-level `message_ack` / `audit_failed`. The chat list MUST upsert by `clientMsgId` instead of blindly appending server echoes.

每条外发聊天消息必须生成并发送唯一 `clientMsgId`，乐观行须携带该字段；收到 `message_delivered`/`message_ack`/`audit_failed` 时必须按 `clientMsgId` upsert，不得盲追加导致重复气泡。

#### Scenario: 发送后不出现重复气泡

- **WHEN** 用户发送一条文本消息且服务端推送 `message_delivered` 给发送方
- **THEN** 聊天列表 SHALL 仅展示一条该消息
- **AND** SHALL 用服务端 `message.id` 替换乐观行而保留同一列表位置

#### Scenario: message_ack 快速确认

- **WHEN** 发送方收到 `{"type":"message_ack","clientMsgId":"..."}`
- **THEN** 客户端 SHALL 将匹配 `clientMsgId` 的乐观行标为已确认（或等待 delivered 合并）
- **AND** SHALL NOT 插入第二条同内容消息

#### Scenario: audit_failed 标失败

- **WHEN** 发送方收到 `{"type":"audit_failed","clientMsgId":"..."}`
- **THEN** 客户端 SHALL 将匹配行标为失败或移除
- **AND** SHALL 向用户展示可读错误

#### Scenario: 重进聊天列表与服务端一致

- **WHEN** 用户发送消息后留在聊天页或重新进入同一会话
- **THEN** 列表行数 SHALL 与 `GET /conversations/{id}/messages` 一致
- **AND** SHALL NOT 出现仅本地存在的重复 `local-*` 行
