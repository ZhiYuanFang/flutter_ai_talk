## MODIFIED Requirements

### Requirement: 绑定后 token 与会话 deviceNo 一致

The system MUST keep the access JWT `device_no` claim consistent with the persisted baby ID after bind, not only SharedPreferences. 系统在宝宝 ID 绑定成功后，**必须**保证 access JWT 内 `device_no` 与持久化宝宝 ID 一致，**不得**仅更新本地 prefs 而不更新会话 token；**不得**在 JWT 仍含与目标 ID 不同的旧 `device_no` 时视为已对齐。

#### Scenario: deviceNo 变更触发 WS 重连且 token 对齐

- **WHEN** `deviceNoNotifierProvider` 从空变为非空（绑定成功）
- **THEN** 下游历史 WS 重连**必须**在 token 含最新 `device_no` 后执行
- **AND** 重连时 `_deviceNoGetter` 与 JWT `device_no`**必须**一致

#### Scenario: 切换绑定至不同宝宝 ID

- **WHEN** 用户将本地宝宝 ID 从 A 绑定/切换为 B，且绑定 API 成功
- **THEN** 客户端**必须** refresh access token 使 JWT `device_no` 等于 B
- **AND** **必须**在 JWT 与 B 一致后才持久化 B 并触发依赖 `deviceNo` 的服务重连
- **AND** 历史 WebSocket auth**不得**再出现「device_no 与 token 不一致」

### Requirement: Reliable Identity Validation for Services

Core services (such as WebSocket) MUST read a consistent baby ID **and** use an access token whose JWT `device_no` matches that ID when subscribing to history push. 核心服务（如 WebSocket）在自动重连或建立链路时，**必须**确保读取到的宝宝 ID 与 access JWT 内 `device_no` 一致；**不得**因 Provider 临时 Loading 回滚为 `null`，**不得**在 JWT 仍缺 `device_no` **或与本地 ID 不一致**时发起 WS auth。

#### Scenario: WebSocket reconnect after binding

- **WHEN** 收到 `deviceNo` 变更通知并触发历史 WS 重连
- **THEN** 内部 `_deviceNoGetter` 获取到的必须是刚绑定成功的 ID
- **AND** 使用的 access token **必须**已在本次绑定后 refresh 且含该 `device_no`

#### Scenario: WebSocket reconnect after binding with stale JWT

- **WHEN** 本地 `deviceNo` 已非空但 JWT 仍无 `device_no` **或 JWT `device_no` 与本地不等**
- **THEN** 服务**必须**先 refresh token，**不得**直接发送 WS auth
