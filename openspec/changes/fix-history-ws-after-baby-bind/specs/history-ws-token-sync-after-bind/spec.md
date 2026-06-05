## ADDED Requirements

### Requirement: 绑定宝宝后必须刷新 access token

The client MUST force a token refresh after a successful baby bind or create (`bindwx` or `auto_save`) before reconnecting the history WebSocket, so the new access JWT includes the latest `device_no` claim from the server. 客户端在宝宝绑定或创建成功（`bindwx` / `auto_save`）后、重连历史 WebSocket **之前**，**必须**强制调用 `POST /device/app/api/token/refresh`（或等价的 `trySilentRefresh`），使新 access JWT 含服务端最新 `device_no` claim。

#### Scenario: 新账号绑定已有宝宝 ID 后 WS 就绪

- **WHEN** 用户已登录且登录响应未带 `deviceNo`，随后通过绑定页成功调用 `bindwx` 并 `setLocal`
- **THEN** 客户端**必须**在重连历史 WS 前完成 token refresh 且新 JWT **必须**含非空 `device_no`
- **AND** 历史 WebSocket **必须**收到 `auth_ok` 且 `isHistoryWebSocketReady` 为 true
- **AND** **不得**向用户 Toast「未绑定设备，无法订阅历史推送」

#### Scenario: 创建新宝宝后 WS 就绪

- **WHEN** 用户通过 `auto_save` 成功创建宝宝并取得 `deviceNo`
- **THEN** 客户端**必须**同样强制 refresh token 后再重连历史 WS
- **AND** WS 鉴权**必须**成功

#### Scenario: refresh 失败

- **WHEN** 绑定成功但 token refresh 失败
- **THEN** 客户端**必须**向用户 Toast 可理解的失败原因（不得 silent fail）
- **AND** **不得**假装 WS 已就绪

### Requirement: 建连前 JWT device_no 与本地 deviceNo 对齐

Before opening a history WebSocket, the client MUST refresh the access token when local `deviceNo` is non-empty but the current JWT lacks a non-empty `device_no` claim. 历史 WebSocket 建连前，若本地 `deviceNo` 非空而当前 access JWT 的 `device_no` claim 为空或缺失，客户端**必须**先 refresh，**不得**直接用旧 token 发送 WS auth。

#### Scenario: 本地已绑定但 JWT  stale

- **WHEN** `_deviceNoGetter()` 返回非空且 JWT 解析无 `device_no`
- **THEN** `_prepareAccessTokenForConnect`（或等价路径）**必须**调用 refresh
- **AND** refresh 成功后**必须**使用新 access 发送 auth 帧

#### Scenario: JWT 已含 device_no

- **WHEN** JWT 已含与本地一致的 `device_no`
- **THEN** 客户端**不得**为对齐而额外 refresh（除非常规过期 refresh 规则触发）

### Requirement: 绑定后重连须 reset strike

After baby bind succeeds, history WebSocket reconnect MUST reset the 3-strike counter and exit `gaveUp` before attempting auth. 宝宝绑定成功后触发历史 WS 重连时，**必须** `resetStrike` 并退出 gave-up，避免因绑定前失败计数导致无法重试。

#### Scenario: 绑定前已 gave-up

- **WHEN** 用户在未绑定阶段 WS 已进入 `gaveUp`，随后完成宝宝绑定
- **THEN** 重连路径**必须** reset strike 后再 attempt
- **AND** 绑定后**必须**能再次自动或手动建连
