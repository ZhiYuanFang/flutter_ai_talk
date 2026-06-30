## ADDED Requirements

### Requirement: Listener-triggered HTTP MUST use in-flight deduplication

When the Flutter client initiates an HTTP request to any app API host (`pangbao.cuplay.top`, `notify.cuplay.top`, or future gateway bases) from a Riverpod `ref.listen`, native SDK callback, `Stream.listen`, or app lifecycle handler, the client MUST coalesce concurrent invocations of the same logical operation into a single in-flight request (single-flight). Subsequent callers MUST await the same `Future` rather than opening a new connection.

当 listener / 回调 / lifecycle 触发同一逻辑的 HTTP 时，客户端必须 single-flight 合并并发调用，后续调用须 await 同一 Future，不得并行重复建连。

#### Scenario: 并发 session 变化仅一次 register

- **WHEN** `sessionProvider.isLoggedIn` 与 `ucgCurrentUserIdProvider` 在短窗口内各触发一次 push register
- **THEN** 客户端 SHALL 仅发起一次 in-flight `POST /push/register`
- **AND** 两路调用 SHALL await 同一 Future 完成后返回

#### Scenario: unread sync 并发合并（既有范例）

- **WHEN** 多路代码同时调用 `syncUcgUnreadFromServer`
- **THEN** 客户端 SHALL 仅发起一次未读 HTTP 请求
- **AND** 后续调用 SHALL await 完成

### Requirement: Listener-triggered HTTP MUST circuit-break after repeated failures

If a listener-triggered HTTP operation fails repeatedly within the same authenticated session (or until explicit session reset such as logout or transport release), the client MUST stop automatic retries for that operation until a reset condition occurs. Reset conditions MUST include at least: user logout, explicit session deactivate, or material input change (e.g. new push token).

listener 触发的 HTTP 在同一会话内连续失败后，客户端必须熔断自动重试，直至登出、显式 deactivate 或输入实质变更（如新 push token）。

#### Scenario: push register 连续失败后熔断

- **WHEN** `POST /push/register` 连续失败达到熔断阈值且用户仍登录
- **THEN** 客户端 SHALL NOT 再自动发起 register
- **AND** SHALL 记录 Debug 日志含 gaveUp 原因

#### Scenario: 登出重置熔断

- **WHEN** 用户登出
- **THEN** push register 熔断状态 SHALL 清零
- **AND** 成功 token 缓存 SHALL 清除

### Requirement: Self-triggering callbacks MUST be ignored during in-flight side-effect HTTP

When a native or SDK callback (e.g. iOS APNs `onTokenRefresh`) can be emitted as a side effect of the same HTTP operation (e.g. `registerForRemoteNotifications` during push register), the client MUST ignore such callbacks while that operation is in-flight. After completion, the client MAY process at most one deferred refresh if the token materially changed.

可能由同一 HTTP 操作触发的原生/SDK 回调（如 register 过程中的 `onTokenRefresh`），在该操作 in-flight 期间客户端必须忽略；完成后若 token 实质变更，最多处理一次 deferred refresh。

#### Scenario: register 进行中忽略 token refresh

- **WHEN** push register HTTP 正在进行
- **AND** 原生层回调 `onTokenRefresh`
- **THEN** 客户端 SHALL NOT 立即发起第二次 register
- **AND** SHALL 在当前 in-flight 结束后再评估是否需要 register

### Requirement: Successful side-effect HTTP SHOULD skip duplicate identical requests

After a successful listener-triggered HTTP call, the client SHOULD cache the stable request identity (e.g. channel + token + deviceKey for push register) and MUST skip a subsequent identical request until the identity changes or the session resets.

成功 POST 后客户端应缓存请求身份（如 push 的 channel+token+deviceKey），身份未变时 MUST 跳过重复 POST，直至身份变更或会话重置。

#### Scenario: 相同 token 跳过重复 register

- **WHEN** push register 已成功且 channel、token、deviceKey 未变
- **AND** session listen 再次触发 register
- **THEN** 客户端 SHALL NOT 发送 `POST /push/register`
- **AND** SHALL 视为已注册成功

#### Scenario: token 变更后重新 register

- **WHEN** 厂商 SDK 上报新 token 且与缓存不同
- **THEN** 客户端 SHALL 再次 POST register（upsert 语义）
