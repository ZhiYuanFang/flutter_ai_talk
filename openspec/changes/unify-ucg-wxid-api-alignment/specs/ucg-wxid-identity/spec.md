## ADDED Requirements

### Requirement: UCG user identity SHALL derive from JWT sub as wxId

The app MUST treat JWT access token `sub` claim as the UCG account identifier (`wxId`), matching gateway injection of `X-Internal-Wx-Id` to ucg-service. `ucgCurrentUserIdProvider` SHALL be synchronized from `sessionProvider` access token on login, refresh, and logout. Profile fetch MAY enrich nickname/avatar but MUST NOT be the sole source of wxId.

#### Scenario: 登录后同步 wxId
- **WHEN** 用户登录成功且 access token `sub` 为 `"12345"`
- **THEN** `ucgCurrentUserIdProvider` SHALL 立即为 `"12345"`，无需等待 `fetchMyProfile` 完成

#### Scenario: 刷新 token 后更新 wxId
- **WHEN** silent refresh 返回新 access token 且 `sub` 变化
- **THEN** UCG 当前用户 ID SHALL 同步更新

#### Scenario: 登出清空 wxId
- **WHEN** 用户登出
- **THEN** `ucgCurrentUserIdProvider` SHALL 置为 null

### Requirement: UCG SHALL NOT require separate login from feeding module

UCG authenticated actions MUST reuse the same `sessionProvider` access token and login flow as the feeding module. The app SHALL NOT introduce a separate UCG login endpoint, token store, or credential prompt beyond existing app login/bind-wechat flows.

#### Scenario: 发帖复用喂养 token
- **WHEN** 已登录用户从 UCG 发布动态
- **THEN** HTTP 请求 SHALL 携带与喂养 API 相同的 Bearer access token

#### Scenario: 无 UCG 独立登录页
- **WHEN** UCG 需要鉴权
- **THEN** App SHALL 引导至现有 `/login` 或绑定流，且 SHALL NOT 展示 UCG 专用账号密码登录

### Requirement: wxId zero device-only sessions SHALL show explicit UCG gate message

When JWT `sub` is `"0"` or empty while `isLoggedIn` may still be true (device-only session), UCG actions requiring a bound WeChat account MUST be blocked with a clear user-facing message (e.g. 请先绑定微信账号后再使用社区功能) and guidance to existing bind/login—not a generic silent failure or misleading「去登录」when already device-authenticated.

#### Scenario: 设备态用户尝试发帖
- **WHEN** 用户已设备登录但 `sub` 为 `"0"` 并尝试发布动态
- **THEN** App SHALL 展示绑定微信提示，且 SHALL NOT 调用 `POST /posts`

#### Scenario: 设备态用户可浏览推荐
- **WHEN** `sub` 为 `"0"` 用户打开推荐 Tab
- **THEN** App SHALL 仍允许匿名加载 `GET /feed/recommend`（与 gateway 白名单一致）

### Requirement: Profile by wxId SHALL support anonymous read via gateway whitelist

`GET /ucg/app/api/profile/{wxId}` MUST be callable without Bearer when gateway anonymous whitelist is configured, enabling read-only他人主页 from Feed avatar tap while logged out.

#### Scenario: 未登录查看他人主页
- **WHEN** 未登录用户从推荐 Feed 点击他人头像
- **THEN** App SHALL 请求 `GET /profile/{wxId}`（`withAuthorization: false` 若网关白名单已配置）并展示只读资料页
