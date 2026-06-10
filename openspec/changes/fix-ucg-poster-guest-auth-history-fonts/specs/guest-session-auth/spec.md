## ADDED Requirements

### Requirement: 冷启动 MUST 静默清理无效会话且不得对游客弹过期 Toast

On cold start, when `ensureFreshSession` fails after token restore, the client SHALL sign out locally without showing the「登录已过期，请重新登录」toast if the user has no valid logged-in session. 冷启动路径在 refresh 失败或 refresh token 缺失时 MUST 仅清除本地 session，不得向游客或已失效会话用户弹出过期登录 Toast。

#### Scenario: 残留过期 token 冷启动

- **WHEN** 本地存有已过期 access 且 refresh 失败或 refresh token 为空
- **THEN** App SHALL 在 Splash 阶段静默 `signOut` 并导航至 `/home`
- **AND** App MUST NOT 展示「登录已过期，请重新登录」Toast

#### Scenario: 有效登录冷启动

- **WHEN** 本地 session 可通过 refresh 恢复为有效登录态
- **THEN** App SHALL 保持登录并正常进入 `/home`
- **AND** 行为 MUST 与变更前一致

### Requirement: 公开 UCG 读接口在游客浏览时 MUST 不带 Bearer

When the user is not logged in, public UCG read HTTP calls (recommend feed, post detail, others' profile and posts) SHALL use `withAuthorization: false` so stale local tokens do not trigger 401 refresh chains. 未登录用户浏览公开 UCG 内容时，推荐 Feed、帖子详情、他人主页与帖子列表等读请求 MUST 设置 `withAuthorization: false`，不得附带过期 Bearer。

#### Scenario: 游客加载推荐 Feed

- **WHEN** 未登录用户打开广场推荐 Tab
- **THEN** `GET /feed/recommend` MUST 以无 Bearer 方式请求并成功展示列表
- **AND** App MUST NOT 因本地残留 token 触发 401 与过期 Toast

#### Scenario: 游客打开他人帖子详情

- **WHEN** 未登录用户从推荐流进入帖子详情
- **THEN** 帖子详情请求 MUST 使用 `withAuthorization: false`
- **AND** App MUST NOT 展示过期登录 Toast

#### Scenario: 已登录用户关注与写操作仍鉴权

- **WHEN** 已登录用户请求关注 Feed、我的帖子或执行点赞/评论/发布
- **THEN** 对应请求 MUST 携带 Bearer
- **AND** 鉴权失败时 MUST 允许 refresh 与过期 Toast（见下条需求）

### Requirement: 真实登录态下的鉴权失败 MUST 仍提示重新登录

When the user is actively logged in and an authorized request or WS connect fails after silent refresh, the client SHALL show「登录已过期，请重新登录」（或等价文案） and sign out. 用户处于有效登录态且主动触发的鉴权请求在静默 refresh 仍失败时，App MUST 登出并 Toast 提示重新登录，不得因本变更而静默吞掉真实过期。

#### Scenario: 已登录发送评论时 token 过期

- **WHEN** 已登录用户发表评论且 access 已失效且 refresh 失败
- **THEN** App MUST 展示「登录已过期，请重新登录」Toast
- **AND** App MUST 清除本地 session

#### Scenario: 已登录喂养主动操作时 WS token 准备失败

- **WHEN** 已登录用户已在主页完成历史初始加载且 WS 建连前 refresh 失败
- **THEN** App MUST 展示会话过期或刷新失败 Toast（与现网一致）
- **AND** App MUST NOT 将此类失败与游客后台路径同等静默

### Requirement: 游客或未登录 surface 上后台 WS refresh 失败 MUST 抑制过期 Toast

When the user is not logged in or is browsing guest-only surfaces, background history WS token preparation failures SHALL NOT show the expired-login toast. 未登录或游客浏览场景下，喂养历史 WS 后台 refresh 失败 MUST 静默返回，不得弹出「登录已过期，请重新登录」。

#### Scenario: 游客停留在主页时 WS 后台尝试

- **WHEN** 未登录用户位于 `/home` 且后台逻辑尝试准备 WS access token
- **THEN** App MUST 直接跳过或静默失败
- **AND** App MUST NOT 展示过期登录 Toast

#### Scenario: 游客浏览 UCG 广场时并行 WS 失败

- **WHEN** 未登录用户在 UCG 广场且并行发生的 WS/session 后台刷新失败
- **THEN** App MUST NOT 展示过期登录 Toast
- **AND** 推荐 Feed 展示 MUST 不受影响
