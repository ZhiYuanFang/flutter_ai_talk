## ADDED Requirements

### Requirement: ucg-service SHALL expose GET /posts/{id} with likedByMe enrichment

Flutter and gateway MUST support `GET /ucg/app/api/posts/{id}` returning a single published post DTO (same shape as feed item plus engagement fields). When the request carries a valid logged-in wxId, the response SHALL include `likedByMe: true|false` from `ucg_post_like`. Anonymous access MAY be allowed for published posts per gateway whitelist (consistent with public profile reads).

#### Scenario: 已登录拉取单帖
- **WHEN** 已登录用户请求 `GET /posts/{id}` 且该帖已发布
- **THEN** 响应 SHALL 含完整帖子字段、`author` enrichment 及正确 `likedByMe`

#### Scenario: 未登录拉取已发布帖
- **WHEN** 匿名请求 `GET /posts/{id}` 且 gateway 白名单允许
- **THEN** 响应 SHALL 返回帖子内容且 `likedByMe` SHALL 为 false

#### Scenario: gateway 白名单
- **WHEN** gateway-app 配置 UCG 匿名可读路由
- **THEN** `GET /posts/{id}` SHALL 出现在白名单中且转发至 ucg-service

### Requirement: Feed and post DTOs SHALL expose authorBio with profile fallback

Post list and single-post responses SHALL include `author.bio` (alias `authorBio`). When the post snapshot lacks bio text, ucg-service SHALL fallback to `GetPublicProfile(authorWxId).Bio` so clients never receive an omitted bio field for feed rendering. Empty profile bio MAY return empty string.

#### Scenario: Feed 作者 bio 回填
- **WHEN** 帖子 DB 快照无 bio 但作者 profile 有简介
- **THEN** Feed DTO `author.bio` SHALL 等于 profile 简介

#### Scenario: 客户端解析 authorBio
- **WHEN** Flutter 解析 Feed 或 `GET /posts/{id}` 响应
- **THEN** `UcgPost` SHALL 映射 `authorBio` 供卡片与详情展示

### Requirement: UcgApiClient SHALL call notification and single-post endpoints

`UcgApiClient` paths MUST include: `GET /posts/{id}`, `GET /notifications/comments`, `POST /notifications/comments/read`. Methods SHALL use canonical gateway prefix `/ucg/app/api` and existing envelope decode.

#### Scenario: fetchPost 路径
- **WHEN** App 打开帖子详情
- **THEN** Client SHALL 调用 `GET /ucg/app/api/posts/{postId}`

#### Scenario: 拉取互动消息
- **WHEN** 用户打开 `UcgInteractionInboxScreen`
- **THEN** Client SHALL 调用 `GET /ucg/app/api/notifications/comments` 并解析分页 envelope

## MODIFIED Requirements

### Requirement: Comment notification DTO SHALL expose postThumbUrl and postMediaKind

`GET /notifications/comments` list items and Flutter `UcgCommentNotification` SHALL include `postThumbUrl` (string) and `postMediaKind` (int: 0=none, 1=image, 2=video) sourced from notification row columns written at insert time. These fields SHALL be optional for backward compatibility with rows created before migration (empty thumb, kind 0).

#### Scenario: API 返回封面快照
- **WHEN** 客户端拉取含图片或视频帖的通知
- **THEN** 响应 item SHALL 含非空 `postThumbUrl`（视频为 OSS snapshot URL）及正确 `postMediaKind`

#### Scenario: Flutter 模型映射
- **WHEN** Flutter 解析 notification JSON
- **THEN** `UcgCommentNotification` SHALL 映射 `postThumbUrl` 与 `postMediaKind` 供 Inbox 缩略图渲染
