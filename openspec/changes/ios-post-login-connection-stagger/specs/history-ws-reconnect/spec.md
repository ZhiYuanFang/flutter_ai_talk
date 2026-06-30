## ADDED Requirements

### Requirement: 登录后历史 WebSocket 建连 MUST 晚于 gateway HTTP bootstrap

The client MUST NOT invoke history WebSocket connect (`setConnectionDesired(true)` or equivalent reconnect) from `feedRepositoryProvider` session or deviceNo listeners at login time. History WebSocket connection MUST be initiated only after `HomeScreen` (or equivalent home owner) has subscribed via `watchLatest()` **and** logged-in gateway HTTP bootstrap (`ColdStartBackgroundSync` or equivalent) has completed. On sign-out the client MUST set connection desired to false and tear down the socket without opening a new connection to the API host.

客户端 MUST NOT 在登录瞬间由 `feedRepositoryProvider` 的 session/deviceNo 监听抢先 reconnect 历史 WebSocket。历史 WS 建连 MUST 在 `HomeScreen` 通过 `watchLatest()` 订阅**且**已登录 gateway HTTP bootstrap（如 `ColdStartBackgroundSync`）**完成之后**才 `setConnectionDesired(true)`。登出时 MUST `setConnectionDesired(false)` 并 tearDown，不得对 API host 发起新 connect。

#### Scenario: 登录成功进主页

- **WHEN** 用户登录成功并导航至 `/home`
- **THEN** `ColdStartBackgroundSync`（或等价）MUST 先完成已登录 catalog/history HTTP sync
- **AND** 历史 WebSocket connect handshake MUST 在上述 sync 完成且 `watchLatest()` 已订阅之后才开始
- **AND** `feedRepositoryProvider` MUST NOT 因 `isLoggedIn` 变为 true 而抢先调用 `reconnectHistoryWebSocket`

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

## MODIFIED Requirements

### Requirement: 会话变更与手动重连 reset strike

The client MUST reset consecutive failure count to 0 and exit gave-up on login, deviceNo change, or manual banner reconnect tap. Login MUST reset strike and permit future reconnect but MUST NOT by itself immediately open a WebSocket connect before gateway HTTP bootstrap and `watchLatest()` subscription as defined in the stagger requirement. 在 **login**、**deviceNo 变更**或用户**手动点击**重连横幅时，客户端必须将连续失败计数 reset 为 **0** 并退出 gave-up。**login** 本身 MUST reset strike 并允许后续 reconnect，但 MUST NOT 在 gateway HTTP bootstrap 与 `watchLatest()` 订阅完成之前因 login 监听 alone 而立即发起 WebSocket connect。

#### Scenario: login 后 bypass gave-up

- **WHEN** 用户重新 login 成功
- **THEN** strike 必须 reset 为 0
- **AND** 必须允许在 bootstrap 与 `watchLatest()` 就绪后再次自动重连（不受此前 gave-up 限制）

#### Scenario: deviceNo 变更 reset

- **WHEN** 本地 deviceNo 发生变更（绑定/切换宝宝）
- **THEN** strike 必须 reset 为 0
- **AND** 必须 tearDown 旧连接并按新 deviceNo 重新 handshake（可由显式 reconnect 或 home 已订阅后的 transport 触发）

#### Scenario: 横幅手动 tap reset

- **WHEN** 用户在 gave-up 或断开态点击重连横幅
- **THEN** strike 必须 reset 为 0
- **AND** 必须立即发起 reconnect（不受 gave-up 阻止）
