## MODIFIED Requirements

### Requirement: Client SHALL register push token on login with bound wxId

The Flutter app MUST detect the device push channel (`apns` on iOS, `hms` on Huawei Android, `mipush` on Xiaomi Android) and obtain the vendor token. When the user is logged in with non-zero wxId (`isUcgWxAccountBound`), the client SHALL call `POST /ucg/app/api/push/register` with `{ channel, token, deviceKey }`. The client MUST NOT use FCM or register on unsupported Android OEMs. On logout, the client SHALL call `POST /ucg/app/api/push/unregister` for the same `deviceKey` (and channel). Push register triggered from session listeners, token refresh callbacks, or UCG home session activation MUST use single-flight deduplication, MUST circuit-break after repeated failures within the same session, MUST ignore self-triggered token refresh events while register is in-flight, and MUST skip duplicate POST when channel, token, and deviceKey are unchanged since the last successful register.

已登录且 wxId 已绑定时，客户端必须检测厂商通道、获取 token 并调用 register；登出必须 unregister。由 session listen、token 回调或 UCG 会话激活触发的 register 必须 single-flight、失败熔断、in-flight 忽略自触发 refresh、成功且身份未变时跳过重复 POST。

#### Scenario: iOS 登录后注册 APNs

- **WHEN** 用户在 iOS 登录且 wxId 非零
- **THEN** App SHALL 获取 APNs device token
- **AND** SHALL POST register body `{ "channel": "apns", "token": "...", "deviceKey": "..." }`

#### Scenario: 华为设备登录后注册 HMS

- **WHEN** 用户在华为 Android 设备登录且 wxId 非零
- **THEN** App SHALL 获取 HMS Push token
- **AND** SHALL POST register with `"channel": "hms"`

#### Scenario: 小米设备登录后注册 MiPush

- **WHEN** 用户在小米 Android 设备登录且 wxId 非零
- **THEN** App SHALL 获取 MiPush token
- **AND** SHALL POST register with `"channel": "mipush"`

#### Scenario: 登出注销 token

- **WHEN** 用户登出
- **THEN** App SHALL POST `/push/unregister` 含当前 `deviceKey`
- **AND** SHALL NOT 在登出后继续持有有效注册行
- **AND** SHALL 清除 push register 熔断状态与成功 token 缓存

#### Scenario: 非华为小米 Android 不注册

- **WHEN** 用户在非华为、非小米 Android 设备登录
- **THEN** App SHALL NOT 调用 push register
- **AND** SHALL NOT 集成 FCM 作为替代

#### Scenario: token 刷新后重新注册

- **WHEN** 厂商 SDK 回调 token 变更且用户仍登录
- **AND** 新 token 与上次成功 register 缓存不同
- **THEN** App SHALL 再次 POST register（upsert 语义）

#### Scenario: register 失败不得无限重试

- **WHEN** `POST /push/register` 连续失败达到客户端熔断阈值
- **THEN** App SHALL NOT 在无 reset 条件下继续自动 register
- **AND** SHALL NOT 因 iOS `onTokenRefresh` 自触发形成重试环

#### Scenario: 相同 token 不重复 POST

- **WHEN** register 已成功且 channel、token、deviceKey 未变
- **AND** UCG home session 或 session listen 再次触发 register
- **THEN** App SHALL NOT 发送重复 `POST /push/register`
