## ADDED Requirements

### Requirement: ucg-service SHALL expose GET /posts/user/{wxId} for published posts by author

The ucg-service MUST provide `GET /ucg/app/api/posts/user/{wxId}` returning a paginated list of **published-only** posts (`status=2`) for the given author. Response envelope and item DTO MUST match `GET /ucg/app/api/posts/mine` (`PostDTO` list with `total`, `page`, `pageSize`). When the request carries a valid logged-in wxId, each item SHALL include correct `likedByMe` via the same enrichment path as Feed and `ListMyPosts`. Anonymous access MAY be allowed per gateway whitelist.

ucg-service 必须提供按作者 wxId 分页拉取**已发布**帖子的接口；响应结构与 `posts/mine` 一致；可选登录态 enrichment `likedByMe`。

#### Scenario: 拉取他人已发布动态
- **WHEN** 客户端请求 `GET /ucg/app/api/posts/user/{wxId}?page=1&pageSize=20` 且该作者有已发布帖
- **THEN** 响应 SHALL 返回 `list` 仅含 `status=2` 帖子，按 `createdAt` 降序
- **AND** `total` SHALL 等于该作者已发布帖总数

#### Scenario: 已登录 likedByMe
- **WHEN** 已登录用户请求 `GET /posts/user/{wxId}`
- **THEN** 每条 `PostDTO` SHALL 含正确 `likedByMe` 字段

#### Scenario: 未登录匿名拉取
- **WHEN** 匿名请求 `GET /posts/user/{wxId}` 且 gateway 白名单允许
- **THEN** 响应 SHALL 返回已发布帖子列表
- **AND** 每条 `likedByMe` SHALL 为 false

#### Scenario: 不含草稿或审核中帖
- **WHEN** 作者存在 `status!=2` 的帖子
- **THEN** `GET /posts/user/{wxId}` 响应 SHALL NOT 包含这些帖子

### Requirement: gateway-app SHALL whitelist anonymous GET /posts/user/

Gateway configuration MUST allow unauthenticated `GET` requests under prefix `/ucg/app/api/posts/user/` to reach ucg-service, consistent with public profile read policy.

gateway 必须将 `/ucg/app/api/posts/user/` 前缀加入 UCG 匿名可读白名单。

#### Scenario: 匿名网关转发
- **WHEN** 未携带 Authorization 的请求访问 `GET /ucg/app/api/posts/user/{wxId}`
- **THEN** gateway SHALL 转发至 ucg-service 并返回 200（作者存在且有已发布帖时）

### Requirement: UcgApiClient SHALL call fetchUserPosts

`UcgRepository` / `UcgApiClient` MUST expose `fetchUserPosts({required String wxId, required int page})` calling `GET /ucg/app/api/posts/user/{wxId}` with canonical gateway prefix and existing envelope decode into `UcgPagedPosts`.

Flutter 客户端必须新增 `fetchUserPosts` 并解析与 `fetchMyPosts` 相同的分页模型。

#### Scenario: 他人主页拉取动态
- **WHEN** App 打开 `UcgUserProfileScreen` 的动态 Tab
- **THEN** Client SHALL 调用 `GET /ucg/app/api/posts/user/{wxId}`

#### Scenario: DTO 映射一致
- **WHEN** Flutter 解析 `fetchUserPosts` 响应
- **THEN** `UcgPost` 列表 SHALL 使用与 `fetchMyPosts` 相同的 JSON 映射逻辑
