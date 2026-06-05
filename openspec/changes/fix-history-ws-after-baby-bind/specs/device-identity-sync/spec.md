## ADDED Requirements

### Requirement: 绑定后 token 与会话 deviceNo 一致

The system MUST keep the access JWT `device_no` claim consistent with the persisted baby ID after bind, not only SharedPreferences. 系统在宝宝 ID 绑定成功后，**必须**保证 access JWT 内 `device_no` 与持久化宝宝 ID 一致，**不得**仅更新本地 prefs 而不更新会话 token。

#### Scenario: deviceNo 变更触发 WS 重连且 token 对齐

- **WHEN** `deviceNoNotifierProvider` 从空变为非空（绑定成功）
- **THEN** 下游历史 WS 重连**必须**在 token 含最新 `device_no` 后执行
- **AND** 重连时 `_deviceNoGetter` 与 JWT `device_no`**必须**一致

## MODIFIED Requirements

### Requirement: Reliable Identity Validation for Services

Core services (such as WebSocket) MUST read a consistent baby ID **and** use an access token whose JWT `device_no` matches that ID when subscribing to history push. 核心服务（如 WebSocket）在自动重连或建立链路时，**必须**确保读取到的宝宝 ID 与 access JWT 内 `device_no` 一致；**不得**因 Provider 临时 Loading 回滚为 `null`，**不得**在 JWT 仍缺 `device_no` 时发起 WS auth。

#### Scenario: WebSocket reconnect after binding

- **WHEN** 收到 `deviceNo` 变更通知并触发历史 WS 重连
- **THEN** 内部 `_deviceNoGetter` 获取到的必须是刚绑定成功的 ID
- **AND** 使用的 access token **必须**已在本次绑定后 refresh 且含该 `device_no`

#### Scenario: WebSocket reconnect after binding with stale JWT

- **WHEN** 本地 `deviceNo` 已非空但 JWT 仍无 `device_no`
- **THEN** 服务**必须**先 refresh token，**不得**直接发送 WS auth
