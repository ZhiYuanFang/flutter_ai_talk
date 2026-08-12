## ADDED Requirements

### Requirement: 主壳激活历史 WebSocket 会话

After the user reaches the authenticated home shell (`UcgHomeShell` or equivalent) and logged-in gateway HTTP bootstrap has completed, the client MUST subscribe to history via `watchLatest()` and MUST call `ensureHistoryWebSocketConnected` (including any platform connect delay such as iOS cooldown) without requiring the feeding `HomeScreen` page to have been mounted. Provider `create`/`build` MUST NOT open the history WebSocket.

用户进入已登录主壳且 gateway HTTP bootstrap 完成后，客户端 MUST 通过 `watchLatest()` 订阅历史并 MUST 调用 `ensureHistoryWebSocketConnected`（含 iOS 等平台冷却）；MUST NOT 要求喂养页 `HomeScreen` 曾挂载。Provider `create`/`build` MUST NOT 建连历史 WebSocket。

#### Scenario: 冷启动默认停在预测页

- **WHEN** 已登录用户冷启动进入 `/home` 且当前页为智能预测，且从未滑入喂养页
- **AND** `GatewayBootstrapGate`（或等价）已完成
- **THEN** 客户端 MUST 完成 `watchLatest` 订阅与历史 WebSocket ensure 建连
- **AND** MUST NOT 等待 `HomeScreen` mount

#### Scenario: 游客不建连

- **WHEN** 用户未登录且位于主壳
- **THEN** 客户端 MUST NOT 将历史 WebSocket `connectionDesired` 设为 true

#### Scenario: 游客转登录

- **WHEN** 用户在主壳 KeepAlive 下完成登录
- **THEN** 客户端 MUST await gateway bootstrap 完成后再 `watchLatest`（若尚未订阅）与 `ensureHistoryWebSocketConnected`
- **AND** MUST NOT 在 `isLoggedIn` 边沿抢先于 bootstrap 建连

### Requirement: 主壳单一消费 History 推送

While the home shell session is active, exactly one application-level subscriber MUST apply History WebSocket payloads to `homeHistory` (upsert/remove) and MUST invoke the shared fly request helper subject to existing visible-page gates. The feeding page MUST NOT run a second payload listener that duplicates upsert or fly requests.

主壳会话激活期间，MUST 仅有一路应用级订阅将 History WS 载荷写入 `homeHistory` 并按既有可见页门闸请求飞入；喂养页 MUST NOT 再挂第二条导致重复 upsert/飞入的 payload 监听。

#### Scenario: 预测页加事件收到推送

- **WHEN** 主壳历史会话已激活且用户仍在预测页
- **AND** History WS 推送一条 create/update 载荷
- **THEN** 客户端 MUST 将记录 upsert 进 `homeHistory`
- **AND** MUST 按 `home-event-record-fly` / 可见页门闸请求飞入（若适用）

#### Scenario: 随后进入喂养页无双飞

- **WHEN** 主壳已持有历史 WS 订阅
- **AND** 用户首次滑入喂养页使 `HomeScreen` mount
- **THEN** 客户端 MUST NOT 因喂养页 mount 再注册第二条 payload→飞入管道
- **AND** 单次 WS create MUST 至多触发一次飞入请求

### Requirement: 传输 gate 与主壳对齐

Token-rotation and authenticated-session reconnect for history WebSocket MUST treat the home **shell** session (not feeding-page widget mount alone) as the mount gate equivalent to today’s `PangbaoHomeTransportGate.isHomeMounted`. Sign-out MUST still release transports and disconnect history WebSocket.

历史 WS 的 token 轮换 / 鉴权会话 reconnect MUST 以主壳会话（而非仅喂养页 widget mount）作为与现 `PangbaoHomeTransportGate.isHomeMounted` 等价的门闸。登出 MUST 仍释放传输并断开历史 WebSocket。

#### Scenario: 仅预测页时 token 轮换仍可重连

- **WHEN** 主壳已激活且喂养页从未 mount
- **AND** access token 非空轮换为另一非空值
- **THEN** 客户端 MUST 仍允许按 `history-ws-reconnect` 触发历史 WS reconnect
- **AND** MUST NOT 因「喂养页未 mount」而跳过 reconnect

#### Scenario: 登出断开

- **WHEN** session `isLoggedIn` 变为 false
- **THEN** 客户端 MUST 断开历史 WebSocket 且 MUST NOT 自动 reconnect
