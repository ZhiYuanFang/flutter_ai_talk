## ADDED Requirements

### Requirement: ucg-service SHALL persist comment and mention notifications in ucg_notification

The backend MUST store in-app notifications for post comments and `@` mentions in a dedicated `ucg_notification` table. Each row SHALL include at minimum: `id`, `recipient_wx_id`, `type` (`comment_on_post` | `mention_in_comment`), `post_id`, `comment_id`, `actor_wx_id`, `preview` (comment excerpt), `read_at` (nullable), and `created_at`. Notifications MUST NOT create or send 1:1 DM conversations (Option A: inbox-only).

#### Scenario: 评论通知写入
- **WHEN** 用户 A 在用户 B 的帖子下发表评论且 A ≠ B
- **THEN** ucg-service SHALL 插入一条 `type=comment_on_post`、`recipient_wx_id=B` 的通知记录

#### Scenario: @ 提及通知写入
- **WHEN** 评论内容解析出 @ 用户 C 且 C ≠ 评论者
- **THEN** ucg-service SHALL 插入一条 `type=mention_in_comment`、`recipient_wx_id=C` 的通知记录

#### Scenario: 不自动发私信
- **WHEN** AddComment 触发任意通知
- **THEN** ucg-service SHALL NOT 调用 `POST /conversations` 或向被 @ 用户发送聊天消息

### Requirement: AddComment SHALL trigger notification hooks with self-skip rules

On successful `POST /posts/{id}/comments`, ucg-service SHALL asynchronously or synchronously: (1) notify the post author when commenter ≠ author; (2) parse `@mentions` in `content` and notify each distinct mentioned user except the commenter. Duplicate recipients for the same comment SHALL receive at most one row per `(recipient, comment_id, type)` tuple.

#### Scenario: 作者评论自己的帖
- **WHEN** 帖子作者在自己帖子下评论
- **THEN** ucg-service SHALL NOT 为 `comment_on_post` 向该作者写入通知

#### Scenario: 评论者 @ 自己
- **WHEN** 评论内容 @ 了评论者本人
- **THEN** ucg-service SHALL NOT 向评论者写入 `mention_in_comment`

### Requirement: Clients SHALL list comment notifications via paginated REST API

Authenticated users MUST be able to fetch inbox items via `GET /ucg/app/api/notifications/comments?page=&pageSize=`. Response SHALL include `list[]` with notification DTOs (actor profile enrichment, `postId`, `commentId`, `type`, `preview`, `read`, `createdAt`) and MAY include `unreadCount`. Gateway SHALL require Bearer for this route (no anonymous access).

#### Scenario: 分页拉取互动消息
- **WHEN** 已登录用户请求 `GET /notifications/comments?page=1&pageSize=20`
- **THEN** 响应 SHALL 按 `created_at` 降序返回通知列表及分页元数据

#### Scenario: 未登录不可访问
- **WHEN** 请求不带有效 Bearer
- **THEN** gateway SHALL 返回 401

### Requirement: Clients SHALL mark comment notifications as read

ucg-service SHALL expose `POST /ucg/app/api/notifications/comments/read` accepting `{ "ids": [number] }` and/or `{ "all": true }` to set `read_at` for the authenticated recipient. Only rows owned by the caller's wxId SHALL be updated.

#### Scenario: 标记单条已读
- **WHEN** 用户 POST read body 含某通知 id
- **THEN** 该条 `read_at` SHALL 被设置且后续列表 `read=true`

#### Scenario: 全部已读
- **WHEN** 用户 POST `{ "all": true }`
- **THEN** 该用户所有未读 comment/mention 通知 SHALL 标记已读

## MODIFIED Requirements

### Requirement: Notification insert SHALL snapshot post cover thumb at write time

Each notification row written by `NotifyOnComment` (for `comment_on_post` and `mention_in_comment`) SHALL include denormalized post cover fields: `post_thumb_url` VARCHAR(512) and `post_media_kind` TINYINT where `0=none`, `1=image`, `2=video`. For each comment event, ucg-service SHALL call `loadPostMedia(ctx, postID)` **exactly once** before inserting notification rows, using the first media item by `sort_order`.

#### Scenario: 图片帖通知封面
- **WHEN** 被评论帖首条媒体为图片（`media_kind=1`）
- **THEN** 写入的 `post_thumb_url` SHALL 等于 `BuildImageThumbnailURL(objectKey)` 且 `post_media_kind=1`

#### Scenario: 视频帖通知封面 Option B
- **WHEN** 被评论帖首条媒体为视频（`media_kind=2`）
- **THEN** 写入的 `post_thumb_url` SHALL 为 OSS 视频截帧 URL（`x-oss-process=video/snapshot,t_0` 作用于 CDN URL）且 `post_media_kind=2`；SHALL NOT 使用 placeholder 或空串代替

#### Scenario: 无媒体帖
- **WHEN** 帖子无 `ucg_post_media` 行
- **THEN** `post_thumb_url` SHALL 为空串且 `post_media_kind=0`

#### Scenario: 每条评论仅一次 loadPostMedia
- **WHEN** 一条评论同时触发帖主通知与多个 @ 通知
- **THEN** ucg-service SHALL 对 `post_id` 仅调用一次 `loadPostMedia` 并将同一 snapshot 写入所有 insert 行

### Requirement: Notification list SHALL NOT batch-enrich posts on read

`GET /notifications/comments` SHALL return stored `postThumbUrl` and `postMediaKind` from each notification row. The list handler MUST NOT batch `loadPostMedia`, join `ucg_post`, or recompute thumbs at read time.

#### Scenario: 列表直接返回快照字段
- **WHEN** 客户端分页拉取互动消息
- **THEN** 每条 DTO SHALL 含 `postThumbUrl` / `postMediaKind` 且值来自 DB 列而非运行时 enrich
