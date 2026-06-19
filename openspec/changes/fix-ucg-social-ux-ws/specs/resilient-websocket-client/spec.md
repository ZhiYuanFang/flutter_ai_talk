## ADDED Requirements

### Requirement: Client SHALL provide a shared resilient WebSocket transport

The Flutter app MUST implement a reusable `ResilientWebSocketClient` (or equivalent) that owns WebSocket connect/teardown, auth handshake, JSON ping/pong heartbeat, exponential backoff reconnect, 3-strike gave-up phase, token preparation hook, and app lifecycle resume reconnect. Domain repositories (feeding history, UCG chat) MUST delegate transport to this client and only handle application-level frames.

客户端必须提供可复用的韧性 WebSocket 传输层，负责建连/拆连、鉴权握手、JSON ping/pong、指数退避重连、3-strike gave-up、token 准备钩子与前台 resume 重连；业务仓库仅处理应用层帧。

#### Scenario: 通道注入不同鉴权帧

- **WHEN** 喂养历史通道配置 `buildAuthFrame` 返回 `{type, accessToken, deviceNo}`
- **THEN** 共享客户端 SHALL 在 `channel.ready` 后发送该帧
- **AND** UCG 通道配置 `{type:auth, token}` 时 SHALL 使用相同握手时序

#### Scenario: 业务帧回调

- **WHEN** 共享客户端收到非 `auth_ok`/`pong`/`error` 的 JSON 帧
- **THEN** 客户端 SHALL 转发至通道注册的 `onApplicationFrame` 回调
- **AND** SHALL NOT 在传输层解析 history 或 chat 业务语义

### Requirement: Shared client SHALL implement JSON ping/pong heartbeat

The shared client MUST send periodic `{"type":"ping"}` after ready and MUST treat only `{"type":"pong"}` as valid heartbeat response. After 2 consecutive missed pongs within timeout, the client MUST tear down the socket and schedule reconnect unless in gave-up phase.

共享客户端必须在就绪后周期性发送 `{"type":"ping"}`，仅接受 `{"type":"pong"}`；连续 2 次超时未收到 pong 必须 tearDown 并调度重连（gave-up 除外）。

#### Scenario: 就绪后 ping 周期

- **WHEN** 某通道完成鉴权并就绪
- **THEN** 共享客户端 SHALL 每 25 秒发送一帧 `{"type":"ping"}`
- **AND** SHALL 在 8 秒内收到 `{"type":"pong"}`，否则记为一次 miss

#### Scenario: 连续 miss 触发重连

- **WHEN** 连续 2 次 ping 未在超时内收到 pong
- **THEN** 共享客户端 SHALL 关闭当前 WebSocket
- **AND** SHALL 进入自动重连流程（若未 gave-up）

### Requirement: Shared client SHALL use exponential backoff and 3-strike gave-up

On disconnect (onError, onDone, heartbeat tearDown, or failed handshake), the shared client MUST reconnect with exponential backoff from 1s to 30s plus 0–500ms jitter unless in gave-up. A failed attempt MUST count as a full handshake cycle; after 3 consecutive failures the client MUST enter gave-up and stop auto-reconnect until `resetStrike()` or explicit user retry.

断开时共享客户端必须指数退避重连（1s→30s + jitter）；完整握手失败计为 1 次 attempt；连续 3 次失败必须 gave-up 并停止自动重连，直至 reset 或用户重试。

#### Scenario: 第三次握手失败 gave-up

- **WHEN** 某通道连续 3 次完整握手失败
- **THEN** 共享客户端 phase SHALL 变为 gave-up
- **AND** SHALL 停止 ping 与自动 schedule 重连

#### Scenario: 成功就绪 reset strike

- **WHEN** 某次 attempt 完成鉴权并就绪（含首次 pong，若通道配置要求）
- **THEN** 连续失败计数 SHALL reset 为 0
- **AND** gave-up 态 SHALL 清除

### Requirement: Shared client SHALL refresh session token before connect

Before each connect attempt, the shared client MUST invoke the channel's `prepareToken()` hook. For authenticated channels this hook MUST call session refresh (`ensureFreshSession` or equivalent) and MUST return null to abort connect when refresh fails.

每次建连前共享客户端必须调用 `prepareToken()`；鉴权通道须刷新 session，刷新失败则不得建连。

#### Scenario: Token 过期后静默刷新再连

- **WHEN** access token 将过期且用户仍登录
- **THEN** `prepareToken()` SHALL 尝试 refresh
- **AND** 成功时 SHALL 使用新 token 发送 auth 帧

### Requirement: Shared client SHALL reconnect on app lifecycle resume

When the app returns to foreground (`AppLifecycleState.resumed`), the shared client MUST attempt reconnect for every channel with `connectionDesired == true` if not ready and not in gave-up, mirroring feeding history behavior.

App 回到前台时，对 `connectionDesired` 为 true 且未就绪、未 gave-up 的通道，共享客户端必须尝试重连。

#### Scenario: 后台回前台补偿重连

- **WHEN** 用户将 App 从后台切回前台且 UCG 通道 desired 为 true 但当前未就绪
- **THEN** 共享客户端 SHALL 调度重连 attempt
- **AND** SHALL NOT 要求用户重新进入 UCG Shell
