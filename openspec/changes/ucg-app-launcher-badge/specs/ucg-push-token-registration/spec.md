## ADDED Requirements

### Requirement: Client SHALL register push token on login with bound wxId

The Flutter app MUST detect the device push channel (`apns` on iOS, `hms` on Huawei Android, `mipush` on Xiaomi Android) and obtain the vendor token. When the user is logged in with non-zero wxId (`isUcgWxAccountBound`), the client SHALL call `POST /ucg/app/api/push/register` with `{ channel, token, deviceKey }`. The client MUST NOT use FCM or register on unsupported Android OEMs. On logout, the client SHALL call `POST /ucg/app/api/push/unregister` for the same `deviceKey` (and channel).

已登录且 wxId 已绑定时，客户端必须检测厂商通道、获取 token 并调用 register；登出必须 unregister；不得使用 FCM；不支持的 Android 厂商不得注册。

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

#### Scenario: 非华为小米 Android 不注册

- **WHEN** 用户在非华为、非小米 Android 设备登录
- **THEN** App SHALL NOT 调用 push register
- **AND** SHALL NOT 集成 FCM 作为替代

#### Scenario: token 刷新后重新注册

- **WHEN** 厂商 SDK 回调 token 变更且用户仍登录
- **THEN** App SHALL 再次 POST register（upsert 语义）

### Requirement: Push register API SHALL persist device tokens in ucg-service

`POST /ucg/app/api/push/register` MUST require Bearer auth with non-zero wxId. ucg-service SHALL upsert into `ucg_push_device` on `(wx_id, device_key, channel)` with columns `token` and `updated_at`. `POST /ucg/app/api/push/unregister` SHALL delete matching rows for the authenticated wxId. Gateway SHALL forward both routes with standard UCG Bearer enforcement.

register/unregister API 必须由 gateway 鉴权转发至 ucg-service，token 持久化于 `ucg_push_device` 表，按 wxId+deviceKey+channel 幂等 upsert。

#### Scenario: register 成功 upsert

- **WHEN** 已登录用户 POST 合法 register body
- **THEN** ucg-service SHALL 写入或更新 `ucg_push_device` 行
- **AND** SHALL 返回 200

#### Scenario: 未登录 register 拒绝

- **WHEN** 请求无有效 Bearer 或 wxId 为零
- **THEN** gateway SHALL 返回 401

#### Scenario: unregister 删除设备行

- **WHEN** 已登录用户 POST unregister 含 `deviceKey`
- **THEN** ucg-service SHALL 删除该 wxId 下匹配 `device_key` 的行（channel 省略时删除该 deviceKey 全部通道）

#### Scenario: 不支持的 channel 拒绝

- **WHEN** register body 中 `channel` 不是 `apns`、`hms`、`mipush` 之一
- **THEN** ucg-service SHALL 返回 400

### Requirement: Client SHALL use stable deviceKey per installation

The client MUST generate or load a persistent `deviceKey` (e.g. UUID stored in secure/local prefs) per app installation. The same `deviceKey` MUST be reused across register/unregister and token refresh for that installation.

每个安装实例必须使用稳定 `deviceKey`，register 与 unregister 须使用同一值。

#### Scenario: 重装后新 deviceKey

- **WHEN** 用户卸载并重装 App
- **THEN** App SHALL 生成新 `deviceKey`
- **AND** 旧设备行 SHALL 在服务端因长期无效 token 清理或用户在新设备 register 后共存（多设备）
