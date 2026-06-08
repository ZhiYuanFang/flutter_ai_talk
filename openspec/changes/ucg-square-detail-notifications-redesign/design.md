## Context

- **现状**：Flutter UCG 广场（`ucg_square_tab.dart`、`ucg_feed_moments_widgets.dart`）采用微信朋友圈单列卡片：内联灰底点赞头像网格、评论预览、「···」浮层菜单。详情页（`ucg_post_detail_screen.dart`）仍带 AppBar 与卡片圆角容器。后端仅有 Feed 列表与 `GET /posts/{id}/comments`、`GET /posts/{id}/likes`，**无**单帖 `GET /posts/{id}`；Feed DTO 的 `author.bio` 可能为空；评论/@ 提及无 inbox 通知。
- **产品目标**：小红书式双列瀑布流 + 沉浸式详情；评论与 @ 通过「互动消息」触达（**Option A**：仅 inbox 通知，**不**自动创建 1:1 DM）。
- **基线**：`openspec/changes/unify-ucg-wxid-api-alignment/specs/**` 定义 Moments 互动块与 Feed 布局；本变更 supersede 其中 Feed 卡片内联互动与单列布局条款。
- **范围**：`d:\work\flutter_ai_talk\app\lib\ucg\` + `d:\work\go_ai_talk` ucg-service + gateway-app。

## Goals / Non-Goals

**Goals:**

- 广场顶栏 inline **推荐 / 关注** Tab（无背景盒）；双列 `MasonryGridView` 瀑布流。
- Feed 卡片：作者 bio（2 行）、心形点赞、图片 lightbox；**无** liker 预览、**无**「···」、**无**内联评论。
- 沉浸式详情：模糊背景、顶栏关注 pill、全量点赞/评论、长按评论 @ 回复、作者删除。
- `GET /posts/{id}` + `likedByMe`；Feed `author.bio` profile fallback。
- `ucg_notification` 表 + 评论/@ 通知 REST；AddComment 写通知（Option A）；**写入时快照帖子封面**（`post_thumb_url` / `post_media_kind`）。
- 消息 Tab **虚拟「互动消息」系统行** → `UcgInteractionInboxScreen` → 帖子详情；Shell 级 WS + 合并未读红点。

**Non-Goals:**

- @ 提及自动发私信或自动 `POST /conversations`（Option A 明确排除）。
- 点赞通知 inbox（MVP 仅评论与 @ 提及）。
- Feed 卡片内联评论输入或快捷评论。
- 服务端 push 通知（APNs/FCM）；MVP 仅应用内 inbox + 可选 WS 帧。

## Decisions

### 1. Feed 布局：`flutter_staggered_grid_view`

- 使用 `MasonryGridView.count(crossAxisCount: 2)`；卡片高度由媒体 aspect + 文本行数决定。
- Tab 控制器保留在 `UcgSquareTab`；移除页面 title/subtitle；Tab 控件嵌入 shell 顶栏行（与 `ucg-visual-system` inline segmented 一致）。
- **替代**：手写 `Wrap` 两列 —— 拒绝（难处理不等高与分页 append）。

### 2. Feed 卡片交互矩阵

| 区域 | 广场 Feed | 我的动态时间轴 |
|------|-----------|----------------|
| 卡片空白/文字 | → 详情 | → 详情 |
| 图片 | → lightbox | → 详情（**不** lightbox） |
| 心形 | 点赞/取消赞 | 同左 |
| 评论 | 仅详情页 | 仅详情页 |

- 心形置于卡片右下，最小 44×44 逻辑像素 hit target；`likedByMe` 驱动填充态。
- **替代**：卡片保留「···」—— 拒绝（产品要求移除）。

### 3. 沉浸式详情页结构

- 单组件 `UcgPostDetailScreen`；入参 `postId`（优先 `fetchPost`）或 seed `UcgPost`（列表带入，进入后 refresh）。
- 背景：`BackdropFilter` + 首图/视频封面/`Theme` shell 色模糊；内容区无圆角卡片包裹。
- 顶栏：`IconButton` 返回 + `UcgAvatar` + 昵称 + `FollowPill`（未关注：实心主色「关注」；已关注：浅色描边「已关注」）。
- 时间行右端「···」→ 现有 detached pill（Like + Comment），与 Feed 旧交互一致但**仅**在详情。
- 点赞区：`GET /posts/{id}/likes` 全量加载（分页 loop 直至完毕或上限 500）；展示头像网格 + 心形（**无** `likeCount` 文案）；心形与首行头像 `CrossAxisAlignment.center`。
- 评论：`GET /posts/{id}/comments` 全量；无「共 N 条」头；长按 → `showModalBottomSheet` 输入框，`@nickname ` 前缀。
- 删除：`post.authorWxId == currentWxId` 时顶栏或 overflow 展示删除，调 `DELETE /posts/{id}`。

### 4. 后端 `GET /posts/{id}`

```text
GET /ucg/app/api/posts/{id}
Authorization: Bearer … (optional for public published post)
Response: UcgPostDTO + likedByMe + author { wxId, nickname, avatarUrl, bio, … }
```

- Handler：校验 published 或 author==viewer；enrich author from `GetPublicProfile`；`likedByMe` from `ucg_post_like` when wxId>0。
- Gateway：匿名可读已发布帖（与 profile 白名单模式一致）。
- Flutter：`UcgRepository.fetchPost(id)` → 详情页 onLoad refresh。

### 5. Feed `author.bio` enrichment

- ucg-service Feed mapper：若 post snapshot `authorBio` 空，则 batch `GetPublicProfile(authorWxId).Bio` fallback；**不得**返回 null/空串给客户端（可 `"` 占位但 prefer 真实 bio）。
- Flutter：`UcgPost.authorBio` 字段；Feed 卡片 `maxLines: 2`；详情 `maxLines: null`。

### 6. 通知数据模型（Option A）

**表 `ucg_notification`（建议字段）：**

| 列 | 说明 |
|----|------|
| id | PK |
| recipient_wx_id | 接收者 |
| type | `comment_on_post` \| `mention_in_comment` |
| post_id | 关联帖 |
| comment_id | 触发评论 |
| actor_wx_id | 评论者 |
| preview | 评论摘要 ≤200 字 |
| **post_thumb_url** | **写入时快照的帖子封面 URL（VARCHAR 512）** |
| **post_media_kind** | **0=none, 1=image, 2=video（TINYINT）** |
| read_at | NULL = 未读 |
| created_at | |

**帖子封面快照（写入时，Option B — OSS video/snapshot）：**

- `NotifyOnComment` 在 insert 任意通知行之前，对 `post_id` 调用 **一次** `loadPostMedia(ctx, postID)`，取首条媒体（`sort_order` 最小）。
- `media_kind=1`（图片）：`post_thumb_url = BuildImageThumbnailURL(objectKey)`，`post_media_kind=1`。
- `media_kind=2`（视频）：`post_thumb_url = BuildCdnURL(objectKey) + "?x-oss-process=video/snapshot,t_0"`（或等价 OSS 视频截帧参数），`post_media_kind=2`；**不得**用 placeholder 或 Feed 侧 poster 占位替代。
- 无媒体：`post_thumb_url=""`，`post_media_kind=0`。
- **列表读取不得** batch `loadPostMedia` 或 join 帖子表 enrich；快照仅写入时计算一次。
- 新增 helper `BuildVideoSnapshotURL(objectKey)`（或内联于 notification 包）作为 notification-only 例外；Feed/详情 DTO 仍按现有规则，不强制 video snapshot URL。

**AddComment hook（事务后异步或同事务）：**

1. 若 `comment.authorWxId != post.authorWxId` → insert `comment_on_post` 给帖子作者。
2. 解析 `content` 中 `@nickname` 或 `@wxId`（与客户端发送格式一致，建议 `@昵称` UTF-8 正则 + 可选 numeric id）。
3. 对每个被 @ 用户（去重、排除 commenter 自身）→ insert `mention_in_comment`。
4. **不得**调用 `CreateConversation` / 发送 DM（Option A）。

**API：**

```text
GET  /ucg/app/api/notifications/comments?page=&pageSize=
POST /ucg/app/api/notifications/comments/read  body: { ids: [] } 或 { all: true }
```

- 列表项 DTO：`id`, `type`, `postId`, `commentId`, `actor{wxId,nickname,avatarUrl}`, `preview`, **`postThumbUrl`**, **`postMediaKind`**, `read`, `createdAt`。
- 未读计数：响应 `unreadCount`；供 Shell 底部「消息」红点与会话 OR 合并。

### 7. Flutter「互动消息」— 虚拟系统行 + Inbox 页

**Supersede**：原 `UcgMessagesTab` 内嵌 flat「互动消息」section（tasks 6.2–6.4 首版实现）改为：

1. **虚拟系统会话行**（置顶）：固定标题「互动消息」、系统图标/占位头像、摘要文案（如「评论与 @ 提及」）、未读角标；**不**占用真实 `ucg_conversation` id；与私信会话同一 `ListView`，位于 conversations 之上。
2. **点击系统行** → `UcgInteractionInboxScreen`：
   - 顶栏 AppBar：标题「互动消息」+ 右侧 **「全部已读」** → `POST /notifications/comments/read { "all": true }`。
   - 列表行：`actor` 头像 + 昵称 + **2 行** `preview`（隐藏 `#wxId` 展示后缀）+ 右侧 **方形** `postThumbUrl` 缩略图（无 thumb 时占位块）；相对时间/未读点。
   - **分页**：滚动触底 load more `GET /notifications/comments?page=`。
   - 点击行 → `UcgPostDetailScreen(postId)`；单条已读 → `POST read { ids: [id] }`。
3. **消息 Tab 会话列表**保留现有 swipe pin/delete；**分页** `GET /conversations`（若尚未实现则补齐）。
4. **未读红点**：`chatUnread OR interactionUnread` → `ucgUnreadCountProvider` → Shell 底部「消息」图标红点（**非**仅消息 Tab 内 section badge）。

### 8. Shell 级 WebSocket

- WS 连接在 **`UcgShell` mount**（已登录且 wxId 绑定）时 `setWsConnectionDesired(true)`，**离开 UCG Shell 时 false**；**不得**仅在 `_onTabTap(3)` 消息 Tab 时连接。
- 监听 `comment_notification` 帧 → `bumpUcgNotificationsRefresh` + 更新未读计数；与 `chat` 帧并列处理。
- `UcgMessagesTab` **不得**单独 toggle WS desired（移除 Tab-local 连接逻辑）。

### 9. @ 提及 Composer 展示层

- **提交 wire**：`POST /posts/{id}/comments` body 含 `@昵称#wxId`（与现有长按预填一致）。
- **展示层**：TextField / 评论列表渲染时仅显示 `@昵称`（strip `#wxId`）；@ 片段 **高亮**（主题色或 span）。
- **原子删除**：Backspace 在 mention 块内或块尾时 **一次删除整段** `@昵称#wxId`（含尾部空格），而非逐字删除。
- 服务端解析不变：优先 `#wxId` 直查，其次 nickname / numeric `@wxId`。

### 10. WebSocket 推送（已实现，Shell 级消费）

- ucg-service 在 insert notification 后向在线 recipient 推送 WS 帧：`{ "type": "comment_notification", "notificationId": … }`。
- Flutter Shell WS 客户端监听并 `invalidate` notifications provider + 未读 badge。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 详情全量评论/点赞性能 | 初期帖子量小可全量；后续可加 cursor 分页但 UI 仍不折叠 |
| nickname @ 解析歧义 | 文档约定；后续可改 `@wxId:123` 精确格式 |
| 双列 + 视频高度抖动 | 固定 video tile max height；首帧 poster 占位 |
| 旧客户端无 notification API | 新字段 optional；旧版忽略互动系统行 |
| 视频 snapshot URL 过期/失效 | 写入 CDN+OSS process URL；与 object 生命周期一致 |
| 后端先于 Flutter 部署 | Feed bio fallback 向后兼容；`GET /posts/{id}` 新端点不影响旧客户端 |

## Migration Plan

1. **go_ai_talk**：DB migration `ucg_notification` → **ALTER 增加 post_thumb_url / post_media_kind** → snapshot helper + 扩展 NotifyOnComment → notification REST DTO → 实现 `GET /posts/{id}` + Feed bio enrichment → gateway 白名单 → 部署 ucg-service + gateway。
2. **Flutter**：依赖 `flutter_staggered_grid_view` → models/repository（`postThumbUrl`/`postMediaKind`）→ 广场/详情 UI → **虚拟系统行 + UcgInteractionInboxScreen** → Shell WS → Composer 展示层 → 联调。
3. **回滚**：保留 Feed 列表路径；新 UI feature flag 可选（非必须）；通知表可停用 hook 不写新行。

## Open Questions

- @ 提及 nickname 重名时通知策略：**已决** — 客户端 `@昵称#wxId` + 服务端 `#wxId` 直查；纯 nickname 重名仍跳过。
- 互动消息未读是否与聊天未读合并为同一 Tab 红点：**已决** — OR 合并，Shell 底部「消息」统一红点。
- 视频通知缩略图：**已决 Option B** — OSS `video/snapshot,t_0` URL 写入 `post_thumb_url`，非 placeholder。
