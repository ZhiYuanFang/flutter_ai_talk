## MODIFIED Requirements

### Requirement: App resume 不得在 gave-up 自动重试

The client MUST NOT automatically retry history WebSocket reconnect on app resume when in gave-up state **unless** the authenticated home shell session is active and the silent-heal budget defined by `history-ws-silent-heal` has not been exhausted; in that case resume MUST be allowed to resetStrike and reconnect once per heal attempt. When the budget is exhausted, resume MUST NOT auto-retry and the client MUST remain in gave-up until manual banner tap, login, or deviceNo change. 当处于 **gave-up** 态时，App resume **默认不得**自动重连；**例外**：已登录主壳会话活跃且 `history-ws-silent-heal` 静默自愈预算未耗尽时，resume MUST 允许 resetStrike 并 reconnect（计入一次自愈）。预算耗尽后 resume MUST NOT 再自动重试，须停留 gave-up 直至手动横幅、login 或 deviceNo 变更。

#### Scenario: resume 时 gave-up 且预算已耗尽

- **WHEN** App resume 且历史 WS phase 为 gave-up
- **AND** 本会话静默自愈预算已耗尽
- **THEN** 客户端**不得**因 lifecycle resume 自动调用 reconnect
- **AND** 必须继续可被手动横幅 / login / deviceNo 变更恢复

#### Scenario: resume 时 gave-up 且预算未耗尽

- **WHEN** App resume 且历史 WS phase 为 gave-up
- **AND** 主壳会话活跃且静默自愈预算未耗尽
- **THEN** 客户端 MUST resetStrike 并尝试 reconnect
- **AND** MUST 将该次计入静默自愈预算

### Requirement: 会话变更与手动重连 reset strike

The client MUST reset consecutive failure count to 0 and exit gave-up on login, deviceNo change, or manual banner reconnect tap. Login MUST reset strike and permit future reconnect but MUST NOT by itself immediately open a WebSocket connect before gateway HTTP bootstrap and home-shell `watchLatest()` subscription as defined in the stagger / shell-session requirements. The home-shell history activation path (after bootstrap) MUST also reset strike before ensure so a prior in-process gaveUp cannot no-op ensure. 在 **login**、**deviceNo 变更**或用户**手动点击**重连横幅时，客户端必须将连续失败计数 reset 为 **0** 并退出 gave-up。**login** 本身 MUST reset strike 并允许后续 reconnect，但 MUST NOT 在 gateway HTTP bootstrap 与主壳 `watchLatest()` 订阅完成之前因 login 监听 alone 而立即发起 WebSocket connect。主壳历史激活路径（bootstrap 之后）MUST 在 ensure 前 resetStrike，避免同进程残留 gaveUp 导致 ensure 空转。

#### Scenario: login 后 bypass gave-up

- **WHEN** 用户重新 login 成功
- **THEN** strike 必须 reset 为 0
- **AND** 必须允许在 bootstrap 与主壳 `watchLatest()` 就绪后再次自动重连（不受此前 gave-up 限制）

#### Scenario: 主壳激活路径 resetStrike

- **WHEN** 主壳在 bootstrap 完成后执行历史 WS 激活（`watchLatest` + ensure）
- **THEN** 客户端 MUST 在 ensure 前将 strike reset 为 0 并退出 gave-up（若曾进入）

#### Scenario: deviceNo 变更 reset

- **WHEN** 本地 deviceNo 发生变更（绑定/切换宝宝，或空变为非空）
- **THEN** strike 必须 reset 为 0
- **AND** 必须 tearDown 旧连接并按新 deviceNo 重新 handshake（可由显式 reconnect、deviceNo 监听或主壳自愈路径触发）

#### Scenario: 横幅手动 tap reset

- **WHEN** 用户在 gave-up 或断开态点击重连横幅
- **THEN** strike 必须 reset 为 0
- **AND** 必须立即发起 reconnect（不受 gave-up 阻止）
