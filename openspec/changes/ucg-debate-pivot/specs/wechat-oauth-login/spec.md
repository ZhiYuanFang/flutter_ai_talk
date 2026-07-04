## ADDED Requirements

### Requirement: Device login SHALL accept miniprogram platform with jscode2session

`POST /device/app/api/login` MUST accept `platform: "miniprogram"` with `code` from `wx.login`. The server MUST exchange the code via WeChat mini program `jscode2session`, resolve `unionid`, and issue JWT identical in shape to App fluwx OAuth login. Invalid or expired codes MUST return 401 with clear error envelope.

device login MUST 支持 `platform=miniprogram` 与 jscode2session，unionid 与 App 一致。

#### Scenario: 小程序合法 code 登录

- **WHEN** 请求体为 `{ "platform": "miniprogram", "code": "<valid>" }`

- **THEN** 响应 SHALL 含 access token 与 refresh 机制（与 App 一致）

#### Scenario: 无效 code 拒绝

- **WHEN** `code` 无效或过期

- **THEN** 服务端 SHALL 返回 401

## MODIFIED Requirements

### Requirement: WeChat OAuth login SHALL remain the App primary path

App fluwx login MUST continue using OAuth2 authorization code flow per existing `wechat-oauth-login` capability. Mini program login is an additional `platform` branch on device-service, not a replacement for App OAuth.

App fluwx OAuth 仍为主路径；小程序为 device login 新增分支。

#### Scenario: App OAuth 不受影响

- **WHEN** App 用户经 fluwx 授权登录

- **THEN** 流程 SHALL 与 v2.0.3 基线一致
- **AND** MUST NOT 要求 `platform=miniprogram`
