## ADDED Requirements

### Requirement: 主壳会话下历史 WS 未就绪须静默自愈

While the authenticated home shell session is active, history WebSocket `watchLatest` is subscribed, `connectionDesired` is true, gateway bootstrap is complete, and a usable `deviceNo` is present, if the history WebSocket is not `ready`, the client MUST silently attempt recovery by resetting the 3-strike / precondition-pause state when needed and invoking reconnect (or equivalent), without requiring the feeding page to mount or the user to tap a banner. 主壳已登录会话活跃、已 `watchLatest`、`connectionDesired==true`、gateway bootstrap 完成且本地 `deviceNo` 非空时，若历史 WS 未 `ready`，客户端 MUST 静默恢复（必要时 resetStrike / 清 precondition pause 并 reconnect），MUST NOT 依赖喂养页 mount 或用户点击横幅。

#### Scenario: 冷启动三振后壳内自愈

- **WHEN** 冷启动主壳已完成 activate（订阅+ensure）且握手连续失败进入 `gaveUp`
- **AND** 静默自愈预算尚未耗尽
- **THEN** 客户端 MUST 在无需用户操作的情况下 resetStrike 并再次发起 reconnect
- **AND** MUST NOT 要求用户先进入喂养页

#### Scenario: precondition paused 后自愈

- **WHEN** 历史 WS 因 `shouldConnect`/`prepareToken` 失败进入 precondition paused 且长期未 `ready`
- **AND** 此后前置条件已可满足（如 deviceNo/token 已齐）且预算未耗尽
- **THEN** 客户端 MUST 清 pause 状态并再次尝试建连
- **AND** 进喂养页 MUST NOT 作为恢复的必要条件

#### Scenario: 自愈预算耗尽

- **WHEN** 主壳会话内针对 gaveUp/paused 的静默自愈次数已达预算上限且仍未 `ready`
- **THEN** 客户端 MUST 停止该会话内的自动静默自愈
- **AND** 既有手动横幅重连（语音模式）与 login/deviceNo 变更路径 MUST 仍可恢复

#### Scenario: ready 后清预算

- **WHEN** 静默自愈或普通握手使历史 WS 进入 `ready`
- **THEN** 客户端 MUST 将本会话静默自愈计数重置为 0

#### Scenario: 登出清预算

- **WHEN** 用户登出或主壳释放传输（`releasePangbaoHomeTransports`）
- **THEN** 客户端 MUST 停止静默自愈并清除预算计数
- **AND** MUST NOT 在登出后继续 reconnect

### Requirement: 壳激活与登录边沿 MUST resetStrike 再 ensure

When the home shell activates the history WebSocket session after login or guest-to-login, the client MUST reset the consecutive failure strike (and exit `gaveUp` if set) before `ensureHistoryWebSocketConnected` (or equivalent reconnect). 主壳在登录后或游客转登录激活历史 WS 会话时，MUST 在 `ensureHistoryWebSocketConnected`（或等价 reconnect）之前 resetStrike 并退出 `gaveUp`。

#### Scenario: 同进程曾 gaveUp 后再次激活

- **WHEN** 同进程内历史 WS 曾进入 `gaveUp`，用户仍保持或重新进入已登录主壳并再次走激活路径
- **THEN** 激活路径 MUST resetStrike
- **AND** 随后的 ensure/reconnect MUST 不被残留 `gaveUp` 空转跳过

#### Scenario: 登录本身不抢连

- **WHEN** 用户 login 成功但 gateway bootstrap 与主壳 `watchLatest` 尚未完成
- **THEN** 客户端 MUST NOT 仅因 login 监听立即建连
- **AND** MUST 仍在 bootstrap + 订阅完成后再 ensure（resetStrike 可在激活路径执行）

### Requirement: App resume 对历史 WS 的编排 MUST 由主壳负责

App lifecycle `resumed` handling that attempts history WebSocket reconnect MUST run from the home shell session owner (or a single delegate it owns), and MUST NOT depend on the feeding `HomeScreen` having been constructed. App lifecycle `resumed` 触发的历史 WS 重连编排 MUST 由主壳会话 owner（或其唯一委托）执行，MUST NOT 依赖喂养 `HomeScreen` 曾被构建。

#### Scenario: 仅预测页回前台

- **WHEN** 用户冷启动后仅停留在预测页（喂养页从未 mount），App 进入后台再 resume
- **AND** 历史 WS `connectionDesired` 且未 `ready`，且（若为 gaveUp）自愈预算未耗尽
- **THEN** 客户端 MUST 尝试恢复历史 WS（含必要时 resetStrike+reconnect）
- **AND** MUST NOT 因喂养页未 mount 而跳过

#### Scenario: 避免双 resume 重连

- **WHEN** 主壳与喂养页均可能观察到 resume
- **THEN** 历史 WS 的 resume 重连 MUST 单一入口 single-flight
- **AND** MUST NOT 并行发起两次独立的 reconnect 风暴

### Requirement: 本地 deviceNo 变为可用时 MUST 唤醒历史 WS

When local `deviceNo` changes from empty to non-empty (or otherwise changes while the shell session allows reconnect), the client MUST resetStrike and reconnect the history WebSocket if the shell mount gate and bootstrap gate allow, without waiting for the bind screen’s explicit call alone. 当本地 `deviceNo` 从空变为非空（或主壳允许 reconnect 时发生变更）时，客户端 MUST 在壳门闸与 bootstrap 门闸允许下 resetStrike 并 reconnect 历史 WS，MUST NOT 仅依赖绑定页显式调用。

#### Scenario: deviceNo 晚到

- **WHEN** 主壳已 ensure 但当时 `shouldConnect` 因无 deviceNo 失败并 eventual pause
- **AND** 随后本地写入非空 deviceNo
- **THEN** 客户端 MUST resetStrike（或清 pause）并 reconnect
- **AND** MUST NOT 要求用户打开喂养页

#### Scenario: 绑定页显式 reconnect 仍合法

- **WHEN** 绑定页成功后调用 `reconnectHistoryWebSocket(resetStrike: true)`
- **THEN** 行为 MUST 仍被允许且与 deviceNo 监听路径幂等（single-flight）
