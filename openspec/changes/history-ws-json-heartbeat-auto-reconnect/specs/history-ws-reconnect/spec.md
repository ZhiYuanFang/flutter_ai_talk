# history-ws-reconnect 变更规格

## ADDED Requirements

### Requirement: 历史 WebSocket JSON 心跳

The client MUST send periodic JSON heartbeat frames `{"type":"ping"}` on the history WebSocket and MUST treat `{"type":"pong"}` as the only valid heartbeat response; plain-text ping/pong MUST NOT be used. 客户端必须在历史 WebSocket 上周期性发送 JSON **`{"type":"ping"}`**，且仅接受 JSON **`{"type":"pong"}`** 作为心跳响应；**不得**使用语音 ASR 等通道的纯文本 ping/pong。

#### Scenario: 就绪后周期性 ping

- **WHEN** 历史 WebSocket 已完成鉴权且心跳子系统已启动
- **THEN** 客户端必须每 **25 秒**发送一帧 `{"type":"ping"}`
- **AND** 必须在 **5 秒**内收到对应 `{"type":"pong"}`，否则该次 ping 记为 miss

#### Scenario: 连续两次 miss 触发 tearDown

- **WHEN** 连续 **2** 次 ping 在超时内未收到 pong
- **THEN** 客户端必须 tearDown 当前 WebSocket（停止 ping、关闭 channel）
- **AND** 必须进入自动重连流程（若未处于 gave-up）

### Requirement: 就绪判定依赖 auth_ok 与首次 pong

The client MUST set `isHistoryWebSocketReady` to true only after receiving `auth_ok` and completing the first successful ping/pong exchange; receiving `auth_ok` alone MUST NOT mark ready. 客户端必须仅在收到 **`auth_ok`** 且完成**首次** ping/pong 成功后，才将 **`isHistoryWebSocketReady`** 置为 `true`；**不得**在仅收到 `auth_ok` 时标记就绪。

#### Scenario: auth_ok 后未收到 pong

- **WHEN** 客户端收到 `auth_ok` 但首次 ping 在 5 秒内未收到 pong
- **THEN** `isHistoryWebSocketReady` 必须保持 `false`
- **AND** 该次完整 handshake 必须计为 **1 次失败 attempt**（见 3-strike 需求）

#### Scenario: 首次 pong 后就绪

- **WHEN** 客户端在 `auth_ok` 之后发送首次 ping 并在 5 秒内收到 `{"type":"pong"}`
- **THEN** `isHistoryWebSocketReady` 必须变为 `true`
- **AND** 连续失败 strike 计数必须 reset 为 **0**

### Requirement: 断开时指数退避自动重连

The client MUST automatically reconnect on any history WebSocket disconnect (onError, onDone, or heartbeat tearDown) using exponential backoff from 1s to 30s with 0–500ms jitter, unless in gave-up state. 任意历史 WebSocket 断开（`onError`、`onDone`、心跳 tearDown）时，客户端必须自动重连，采用指数退避 **1s→30s** 并加 **0–500ms** 随机 jitter；**gave-up** 态除外。

#### Scenario: onDone 触发退避重连

- **WHEN** 历史 WebSocket `onDone` 且当前未处于 gave-up
- **THEN** 客户端必须在退避 delay 结束后发起新的 connect
- **AND** 退避等待期间**不得**计为一次 attempt

#### Scenario: gave-up 时不自动重连

- **WHEN** 客户端处于 gave-up 态
- **THEN** 客户端**不得**因 onError/onDone/heartbeat 再次自动 schedule 重连
- **AND** 必须停止 ping 定时器

### Requirement: 三次连续失败放弃（3-strike）

The client MUST count one failed attempt as a full handshake cycle (connect → auth → auth_ok → first ping → first pong); after 3 consecutive failed attempts it MUST enter gave-up and stop auto-reconnect and heartbeat. 一次失败 attempt 定义为完整握手周期：**connect → auth → auth_ok → first ping → first pong** 中任一步失败；连续 **3** 次失败后必须进入 **gave-up**，停止自动重连与 ping。

#### Scenario: 握手任一步失败累加 strike

- **WHEN** 某次 attempt 在 connect、auth 发送、auth_ok、首次 ping 或首次 pong 任一步失败
- **THEN** 连续失败计数必须 **+1**
- **AND** 若计数 < 3，必须在退避后发起下一次 attempt

#### Scenario: 第三次失败进入 gave-up

- **WHEN** 连续失败计数达到 **3**
- **THEN** 客户端必须进入 gave-up phase
- **AND** 必须停止自动重连与 ping

#### Scenario: 成功就绪 reset strike

- **WHEN** 某次 attempt 完成首次 pong 并就绪
- **THEN** 连续失败计数必须 reset 为 **0**
- **AND** gave-up 态必须清除（若曾进入）

#### Scenario: 冷启动首次 connect 计入 strike

- **WHEN** 应用冷启动后 `watchLatest()` 触发历史 WebSocket 的**首次** connect，且该次完整 handshake 失败
- **THEN** 该失败必须计入连续失败计数（与断线后重连失败同等对待）
- **AND** **不得**因「首次连接」而豁免 strike

#### Scenario: 退避等待不计 attempt

- **WHEN** 客户端处于指数退避等待窗口
- **THEN** 该等待**不得**计为一次 attempt
- **AND** 仅在新 handshake 开始时计为新 attempt

### Requirement: 会话变更与手动重连 reset strike

The client MUST reset consecutive failure count to 0 and exit gave-up on login, deviceNo change, or manual banner reconnect tap. 在 **login**、**deviceNo 变更**或用户**手动点击**重连横幅时，客户端必须将连续失败计数 reset 为 **0** 并退出 gave-up。

#### Scenario: login 后 bypass gave-up

- **WHEN** 用户重新 login 成功
- **THEN** strike 必须 reset 为 0
- **AND** 必须允许再次自动重连（不受此前 gave-up 限制）

#### Scenario: deviceNo 变更 reset

- **WHEN** 本地 deviceNo 发生变更（绑定/切换宝宝）
- **THEN** strike 必须 reset 为 0
- **AND** 必须 tearDown 旧连接并按新 deviceNo 重新 handshake

#### Scenario: 横幅手动 tap reset

- **WHEN** 用户在 gave-up 或断开态点击重连横幅
- **THEN** strike 必须 reset 为 0
- **AND** 必须立即发起 reconnect（不受 gave-up 阻止）

### Requirement: App resume 不得在 gave-up 自动重试

The client MUST NOT automatically retry history WebSocket reconnect on app resume when in gave-up state. 当处于 **gave-up** 态时，App 从后台 **resume****不得**自动触发历史 WebSocket 重连。

#### Scenario: resume 时 gave-up

- **WHEN** App resume 且历史 WS phase 为 gave-up
- **THEN** 客户端**不得**因 lifecycle resume 自动调用 reconnect
- **AND** 必须继续展示 gave-up 横幅直至用户手动 tap 或 login/deviceNo 变更

### Requirement: 历史 WS phase 流

The client MUST expose a stream of history WebSocket phases including at least `ready`, `autoReconnecting`, and `gaveUp` for UI binding. 客户端必须暴露历史 WebSocket **phase** 流，至少包含 **`ready`**、**`autoReconnecting`**、**`gaveUp`**，供 UI 绑定。

#### Scenario: 自动重连中 phase

- **WHEN** 客户端在退避后正在执行 reconnect handshake
- **THEN** phase 必须为 **`autoReconnecting`**
- **AND** `isHistoryWebSocketReady` 必须为 `false`

#### Scenario: 就绪 phase

- **WHEN** 首次 pong 完成且心跳运行中
- **THEN** phase 必须为 **`ready`**
- **AND** `isHistoryWebSocketReady` 必须为 `true`

### Requirement: 重连前刷新 access token

The client MUST call `ensureFreshSession()` (or equivalent silent refresh when access is expired or within the refresh buffer) immediately before each history WebSocket connect attempt and before sending the auth frame; on refresh failure it MUST sign out and MUST NOT count the attempt toward 3-strike. 每次历史 WebSocket **connect attempt** 在发送 auth 帧之前，若 access token 已过期或即将过期，客户端**必须**先尝试静默 refresh；refresh **成功**后再用新 token 发 auth；refresh **失败**则**必须**登出并提示用户，且**不得**将该次计入 3-strike。

#### Scenario: 即将过期时 refresh 后 auth

- **WHEN** 客户端发起 handshake 且 access token 距过期不足 refresh buffer
- **THEN** 客户端必须先 refresh 成功
- **AND** 必须使用 refresh 后的 accessToken 发送 auth 帧

#### Scenario: refresh 失败登出

- **WHEN** handshake 前 refresh 失败
- **THEN** 客户端必须 signOut（或等价登出）
- **AND** 必须向用户提示登录已过期
- **AND** 不得 schedule 自动重连或累加 strike
