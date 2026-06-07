# UCG Flutter ↔ go_ai_talk ucg-service 路径/方法对照清单

Gateway 前缀：`/ucg/app/api`（HTTP）、`/ucg/app/ws/chat`（WS 代理至 ucg-service `/ws/chat`）。

| 功能 | Flutter `UcgRepository` | HTTP | 请求体 canonical 字段 | 响应关键字段 |
|------|-------------------------|------|----------------------|--------------|
| 推荐 Feed | `fetchRecommendedFeed` | `GET /feed/recommend` | query: `page`, `pageSize`；已登录时带 Bearer | `{ list, total, page, pageSize }`，帖子 `authorWxId`, `content`, `status`(int), `media[]`（`objectKey`, `cdnUrl`, `mediaKind`, 可选 `thumbnailUrl`/`thumbKey`）, `likedByMe`（已登录 wxId>0） |
| 关注 Feed | `fetchFollowingFeed` | `GET /feed/following` | 同上 | 同上 |
| 我的动态 | `fetchMyPosts` | `GET /posts/mine` | 同上 | 含 pending/rejected status |
| 我的资料 | `fetchMyProfile` | `GET /profile/me` | Bearer | `wxId`, `nickname`, `avatarKey`, `bio`, `ipLocation` |
| 更新资料 | `updateMyProfile` | **PUT** `/profile/me` | `nickname`, `avatarKey`, `bio`（**无** `ipLocation`） | `UcgProfileRes` |
| 他人资料 | `fetchProfile(wxId)` | `GET /profile/{wxId}` | 匿名（gateway 白名单） | `wxId`, `ipLocation` |
| 媒体 presign | `presignMedia` | `POST /media/presign` | `mediaKind`(1/2), `extension` | `uploadUrl`, `objectKey`, `cdnUrl`, `headers` |
| 媒体上传（Web 代理） | `uploadMediaViaGateway` | `POST /media/upload` | multipart: `file`, `mediaKind`, `extension` | `objectKey`, `cdnUrl` |
| 发帖 | `createPost` | `POST /posts` | `content`, `mediaType`, `submit`, `media[]`（**无** `ipLocation`） | `UcgPostItem`（含 `ipLocation` 快照） |
| 删帖 | `deletePost` | **DELETE** `/posts/{id}` | — | — |
| 点赞 | `likePost` | **POST** `/posts/{id}/like` | `{}` | — |
| 取消赞 | `unlikePost` | **DELETE** `/posts/{id}/like` | — | — |
| 点赞名单 | `fetchPostLikes` | **GET** `/posts/{id}/likes` | query 分页 | `list[].wxId`, `list[].nickname`, `list[].avatarKey`, `list[].avatarUrl`（服务端 `GetPublicProfile`；头像缺失时客户端占位） |
| 评论列表 | `fetchComments` | `GET /posts/{id}/comments` | query 分页 | `list[].content`, `authorWxId` |
| 发表评论 | `addComment` | `POST /posts/{id}/comments` | `content` | `UcgCommentItem` |
| 删评论 | `deleteComment` | **DELETE** `/comments/{id}` | — | — |
| 关注 | `followUser` | **POST** `/follow/{wxId}` | `{}` | — |
| 取关 | `unfollowUser` | **DELETE** `/follow/{wxId}` | — | — |
| 关注列表 | `fetchFollowingList` | `GET /follow/following` | query 分页 | `list` 为 wxId 数组 |
| 会话列表 | `fetchConversations` | `GET /conversations` | query 分页 | `peerWxId`, `lastPreview`, `pinned` |
| 创建会话 | `createConversation` | **POST** `/conversations` | `targetWxId` | `UcgConversationItem` |
| 历史消息 | `fetchChatHistory` | `GET /conversations/{id}/messages` | query 分页 | `senderWxId`, `content` |
| 置顶会话 | `pinConversation` | **PUT** `/conversations/{id}/pin` | `pinned` | — |
| 标记已读 | `markConversationRead` | **POST** `/conversations/{id}/read` | `lastMsgId`（可选） | — |
| 删会话 | `deleteConversation` | **DELETE** `/conversations/{id}` | — | — |

## 帖子 status 整型（`internal/services/ucg/constants.go`）

| 值 | 含义 |
|----|------|
| 0 | draft |
| 1 | pending_audit |
| 2 | published |
| 3 | rejected |

## WebSocket 帧（ucg-service `ucg_chat_ws.go`）

| 方向 | type | 字段 |
|------|------|------|
| 客户端 → 服务端 auth | `auth` | `token`（JWT access token） |
| 服务端 → 客户端 | `auth_ok` | `wxId` |
| 客户端 → 服务端发消息 | `message` | `conversationId`, `content`, `clientMsgId`（可选）, `imageKey` / `videoKey`（可选，互斥） |
| 服务端 → 客户端 | `message_ack` | `clientMsgId` |
| 服务端 → 客户端 | `message_delivered` | `conversationId`, `message`（含 `imageKey`/`videoKey`/`mediaCdnUrl`） |
| 服务端 → 客户端 | `audit_failed` | `clientMsgId`, `reason` |
| 心跳 | `ping` / `pong` | — |

## Gateway 匿名白名单（`gateway_app_auth_exempt.go`）

- `GET /ucg/app/api/feed/recommend` ✓
- `GET /ucg/app/api/profile/{wxId}` ✓（前缀 `/ucg/app/api/profile/`，排除 `/profile/me`）
- `GET /ucg/app/ws/chat`（Upgrade，HTTP 层无 Bearer；WS 内 auth 帧鉴权）

## Web 媒体上传与 CORS（`gateway_app_cors.go` + `ucg_route_proxy.go`）

- 浏览器从 `http://localhost:*` 发 `POST /ucg/app/api/media/upload`（multipart + `Authorization`）会先 **OPTIONS** 预检。
- **gateway-app** 的 `installGatewayAppCORSMiddleware` 对任意 OPTIONS 返回 **204** 并写入 CORS 头（`localhost` 在白名单）。
- **UCG HTTP 反代**（`/ucg/app/api/*`）**不得**把 OPTIONS 透传到 ucg-service：下游仅注册 POST `/media/upload`，预检会 **405**。
- 实际文件上传：`POST /ucg/app/api/media/upload` → gateway 反代 → ucg-service `ucgMediaUpload` → OSS；移动端仍走 `POST /media/presign` + 直传 OSS。

## 身份

- JWT `sub` = 微信 `wx.id`；gateway 注入 `X-Internal-Wx-Id` 转发 ucg-service。
- `sub=0`：设备态，可看推荐，不可发帖/互动/私信。
