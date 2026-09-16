## ADDED Requirements

### Requirement: Client SHALL register push tokens via global app API when logged in
The client SHALL register and unregister vendor push tokens using `POST /app/api/push/register` and `POST /app/api/push/unregister` with Bearer auth, body fields `channel`, `token`, and `deviceKey`. Registration MUST be treated as an app-global capability and MUST NOT depend on UCG home session activation, UCG chat WebSocket readiness, or WeChat-binding checks. JWT `wxId` on the server means the logged-in user id only. 推送注册 **必须** 走全局 `/app/api/push/*`；**必须** 仅以已登录为门闸；**不得** 依赖 UCG 会话/WS/绑微信。

#### Scenario: Register after login without WeChat bind check
- **WHEN** 用户已登录（含未绑定微信社区能力的账号）且设备可取得厂商 token
- **THEN** 客户端 MUST 允许调用 `POST /app/api/push/register`（在 channel 可映射时）

#### Scenario: Must not use deleted UCG push paths
- **WHEN** 客户端发起推送注册或注销
- **THEN** 请求 path MUST 为 `/app/api/push/register` 或 `/app/api/push/unregister`；MUST NOT 调用 `/ucg/app/api/push/*`

#### Scenario: Decoupled from UCG session
- **WHEN** UCG chat WebSocket 未就绪或 `activateUcgHomeSession` 未完成
- **THEN** 客户端仍 MUST 允许在已登录条件下尝试全局 push 注册

#### Scenario: Logout unregisters
- **WHEN** 用户登出
- **THEN** 客户端 MUST 调用（或尝试）`POST /app/api/push/unregister` 并清理本地注册缓存

### Requirement: Global push registration SHALL keep operational safeguards
The global registration flow SHALL keep a stable `deviceKey`, single-flight in-flight protection, and failure circuit-breaking / short cooldown, and MUST skip duplicate POSTs when channel, token, and deviceKey are unchanged. 全局注册 **必须** 保留 deviceKey、single-flight 与失败熔断；指纹未变 **必须** 跳过重复 POST。

#### Scenario: Skip duplicate register
- **WHEN** channel、token、deviceKey 与上次成功注册一致
- **THEN** 客户端 MUST NOT 重复 POST register
