## ADDED Requirements

### Requirement: UcgApiClient SHALL expose vote and debate post fields

`UcgApiClient` MUST add `POST /posts/{id}/vote` with body `{ "side": "left"|"right" }`. Post and author DTOs MUST parse `type`, `debateLeft`, `debateRight`, `leftVoteCount`, `rightVoteCount`, `myVoteSide`, and `author.forceValue`. Feed fetch methods MUST append `type=debate` for square tabs.

`UcgApiClient` MUST 暴露 vote 接口与 debate 相关 DTO 字段；广场 Feed MUST 传 `type=debate`。

#### Scenario: 投票请求路径

- **WHEN** App 对帖子投 right 票
- **THEN** Client SHALL `POST /ucg/app/api/posts/{id}/vote` body `{ "side": "right" }`

#### Scenario: 解析辩论帖 DTO

- **WHEN** Feed 返回 `type: "debate"` 与 `debateLeft`/`debateRight`
- **THEN** `UcgPost.fromJson` SHALL 填充对应字段供 `UcgDebateVsBar` 使用

## MODIFIED Requirements

### Requirement: UcgApiClient SHALL use canonical ucg-service HTTP paths and methods

Flutter UCG HTTP calls MUST align with `go_ai_talk` ucg-service routes exposed via gateway `/ucg/app/api`. `UcgApiClient` SHALL use real HTTP verbs: GET for reads, POST for creates, PUT for updates, DELETE for removals. Paths MUST include at minimum: `GET /feed/recommend` (not `/feed/recommended`), `GET /feed/following`, `GET/PUT /profile/me`, `GET /profile/{wxId}`, `POST /posts`, `POST /media/presign`, `POST/DELETE /posts/{id}/like`, `POST /posts/{id}/vote`, `GET/POST /posts/{id}/comments`, `DELETE /comments/{id}`, `POST/DELETE /follow/{wxId}`, `GET /follow/following`, `GET/POST /conversations`, `GET /conversations/{id}/messages`, `PUT /conversations/{id}/pin`, `DELETE /conversations/{id}`. Feed GETs for square MUST pass `type=debate`. Like endpoints MUST NOT be invoked by client for `type=debate` posts.

Flutter UCG HTTP 须对齐 gateway 路径；新增 `POST /posts/{id}/vote`；广场 Feed GET MUST 带 `type=debate`；debate 帖客户端 MUST NOT 调用 like。

#### Scenario: 推荐流使用正确路径

- **WHEN** App 请求推荐 Feed 第一页

- **THEN** Client SHALL 调用 `GET /ucg/app/api/feed/recommend?page=1&pageSize=20&type=debate`，且 SHALL NOT 使用 `/feed/recommended`

#### Scenario: 取消点赞使用 DELETE

- **WHEN** 已登录用户对 **moment** 帖长按撤销自己的点赞

- **THEN** Client SHALL 发送 `DELETE /ucg/app/api/posts/{postId}/like`，且 SHALL NOT 用 POST 冒充 DELETE

#### Scenario: 辩论帖不调用 like

- **WHEN** UI 展示 `type=debate` 帖子

- **THEN** Client MUST NOT 发送 like POST/DELETE

#### Scenario: 置顶会话使用 PUT

- **WHEN** 用户在会话列表左滑置顶

- **THEN** Client SHALL 发送 `PUT /ucg/app/api/conversations/{id}/pin` 且 body 含 `pinned` 字段

### Requirement: UCG DTOs SHALL map canonical backend field names

Request bodies MUST send backend-canonical fields: post body `content` (not only `text`), `type`, `debateLeft`, `debateRight` for debate posts, comment `content`, presign fields per ucg-service spec. Response parsing MUST accept `wxId` / `userId`, `authorWxId` / `authorId`, `content` / `text` as aliases. Post `status` MUST support integer enum from API with mapping to `UcgPostStatus`. Debate posts MUST expose vote fields `leftVoteCount`, `rightVoteCount`, `myVoteSide`. Author MUST expose `forceValue`.

请求体须含 `type`、`debateLeft`、`debateRight`；响应须解析投票与原力字段。

#### Scenario: 发帖请求体含 content

- **WHEN** 用户提交辩论动态

- **THEN** `POST /posts` body SHALL 包含 `content`、`type`、`debateLeft`、`debateRight`

#### Scenario: 解析他人帖子作者 wxId

- **WHEN** Feed 响应含 `authorWxId` 而无 `authorId`

- **THEN** `UcgPost.fromJson` SHALL 正确填充作者标识供 UI 与跳转使用

#### Scenario: 解析整型帖子状态

- **WHEN** API 返回 `status: 2` 表示已发布

- **THEN** Client SHALL 映射为 `UcgPostStatus.published` 并在公开 Feed 展示
