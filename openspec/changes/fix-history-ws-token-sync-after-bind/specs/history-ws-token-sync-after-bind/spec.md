## MODIFIED Requirements

### Requirement: 建连前 JWT device_no 与本地 deviceNo 对齐

Before opening a history WebSocket, the client MUST refresh the access token when local `deviceNo` is non-empty but the current JWT lacks a non-empty `device_no` claim **or** the JWT `device_no` does not equal local `deviceNo`. 历史 WebSocket 建连前，若本地 `deviceNo` 非空，而当前 access JWT 的 `device_no` claim 为空、缺失**或与本地 `deviceNo` 不一致**，客户端**必须**先 refresh，**不得**直接用旧 token 发送 WS auth。

#### Scenario: 本地已绑定但 JWT stale

- **WHEN** `_deviceNoGetter()` 返回非空且 JWT 解析无 `device_no`
- **THEN** `_prepareAccessTokenForConnect`（或等价路径）**必须**调用 refresh
- **AND** refresh 成功后**必须**使用新 access 发送 auth 帧

#### Scenario: JWT 已含 device_no

- **WHEN** JWT 已含与本地一致的 `device_no`
- **THEN** 客户端**不得**为对齐而额外 refresh（除非常规过期 refresh 规则触发）

#### Scenario: 切换宝宝后 JWT 含旧 device_no

- **WHEN** 本地目标 `deviceNo` 为 B，但 JWT `device_no` 仍为 A（A 非空且 A ≠ B）
- **THEN** 客户端**必须**在发送 WS auth 前 refresh access token
- **AND** refresh 后 JWT `device_no`**必须**等于 B
- **AND** auth 帧中 `deviceNo` 与 JWT `device_no`**必须**均为 B
- **AND** **不得**向用户 Toast「device_no 与 token 不一致」

## ADDED Requirements

### Requirement: 绑定流程须在 setLocal 之前完成 token 对齐

After a successful `bindwx`, `auto_save`, or username device bind API call, the client MUST align the access JWT with the target baby ID **before** persisting that ID via `setLocal` and before any history WebSocket reconnect triggered by `deviceNoNotifierProvider`. 绑定相关 API 成功后，客户端**必须**在调用 `setLocal` 更新本地宝宝 ID **之前**完成 access JWT 与目标 ID 的对齐；**不得**在 token 仍含旧 `device_no` 时因 `setLocal` 触发 Provider 监听而抢先发起 WS auth。

#### Scenario: bindwx 成功且 JWT 含旧宝宝 ID

- **WHEN** `bindwx` 成功，目标宝宝 ID 为 B，JWT 当前 `device_no` 为 A
- **THEN** 客户端**必须**先 refresh 并校验 JWT `device_no` 等于 B
- **AND** **仅当**校验通过后**方可** `setLocal(B)`
- **AND** 随后触发的历史 WS 重连**必须**收到 `auth_ok`

#### Scenario: token 对齐失败不得写入本地宝宝 ID

- **WHEN** 绑定 API 成功但 refresh 失败或 refresh 后 JWT 仍与目标 ID 不一致
- **THEN** 客户端**必须** Toast 可理解失败原因
- **AND** **不得** `setLocal` 目标 ID
- **AND** **不得**向用户暗示 WS 已就绪
