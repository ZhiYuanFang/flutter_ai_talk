## MODIFIED Requirements

### Requirement: 登录后历史 WebSocket 建连 MUST 晚于 gateway HTTP bootstrap

The client MUST NOT invoke history WebSocket connect (`setConnectionDesired(true)` or equivalent reconnect) from `feedRepositoryProvider` session or deviceNo listeners at login time. History WebSocket connection MUST be initiated only after the home **shell** owner (`UcgHomeShell` or equivalent, not the feeding `HomeScreen` page alone) has subscribed via `watchLatest()` **and** logged-in gateway HTTP bootstrap (`ColdStartBackgroundSync` or equivalent) has completed. On sign-out the client MUST set connection desired to false and tear down the socket without opening a new connection to the API host.

客户端 MUST NOT 在登录瞬间由 `feedRepositoryProvider` 的 session/deviceNo 监听抢先 reconnect 历史 WebSocket。历史 WS 建连 MUST 在**主壳**（`UcgHomeShell` 或等价 home owner，而非仅喂养页 `HomeScreen`）通过 `watchLatest()` 订阅**且**已登录 gateway HTTP bootstrap（如 `ColdStartBackgroundSync`）**完成之后**才 `setConnectionDesired(true)`。登出时 MUST `setConnectionDesired(false)` 并 tearDown，不得对 API host 发起新 connect。

#### Scenario: 登录成功进主页

- **WHEN** 用户登录成功并导航至 `/home`
- **THEN** `GatewayBootstrapGate`（或等价）MUST 先完成已登录 catalog/history HTTP sync 与 `loadBaby`
- **AND** 历史 WebSocket connect handshake MUST 在上述 sync 完成、post-login bootstrap（如 version/check）完成、主壳 `watchLatest()` 已订阅且（iOS 上）冷却延迟之后才开始
- **AND** MUST NOT 要求用户先进入喂养页
- **AND** `feedRepositoryProvider` MUST NOT 因 `isLoggedIn` 变为 true 而抢先调用 `reconnectHistoryWebSocket`

#### Scenario: KeepAlive 下游客转登录

- **WHEN** 用户以游客身份已在 `/home`（主壳 KeepAlive）并完成登录
- **THEN** 客户端 MUST await `GatewayBootstrapGate.ensureLoggedInComplete` 后再 `ensureHistoryWebSocketConnected`
- **AND** MUST NOT 在 `isLoggedIn` listen 中并行发起 catalog/history HTTP refresh 与 WS 建连

#### Scenario: 登出 tearDown

- **WHEN** 用户登出且 session `isLoggedIn` 变为 false
- **THEN** 客户端 MUST 关闭历史 WebSocket 且 MUST NOT 自动 reconnect
- **AND** 对 `AppEnv.apiBaseUrl` 的无鉴权 HTTP（如游客打开隐私政策）MUST 仍可正常发起

#### Scenario: Token 轮换 reconnect 仍保留

- **WHEN** 用户已登录且 access token 从非空轮换为另一非空值
- **THEN** 客户端 MUST 仍按 `history-ws-reconnect` 既有规则触发 reconnect
- **AND** 该 reconnect MUST NOT 因本 Requirement 而被永久禁用

#### Scenario: 绑定宝宝后显式 reconnect

- **WHEN** 用户在绑定页成功绑定或创建宝宝并调用显式 `reconnectHistoryWebSocket(resetStrike: true)`
- **THEN** 客户端 MUST 允许立即 reconnect（不受「须等 Home bootstrap」限制）
- **AND** MUST reset strike 并按新 deviceNo handshake

#### Scenario: 默认预测页无需先访问喂养

- **WHEN** 已登录用户进入 `/home` 且 `homePagerIndex` 为预测页，喂养页尚未构建
- **THEN** 主壳 MUST 仍完成 `watchLatest` 与 ensure 建连（在 bootstrap 之后）
- **AND** History WS 推送 MUST 能更新 `homeHistory`
