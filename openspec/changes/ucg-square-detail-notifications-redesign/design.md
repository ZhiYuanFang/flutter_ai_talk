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
- `ucg_notification` 表 + 评论/@ 通知 REST；AddComment 写通知（Option A）。
- 消息 Tab「互动消息」列表 → 帖子详情。

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
| read_at | NULL = 未读 |
| created_at | |

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

- 列表项 DTO：`id`, `type`, `postId`, `commentId`, `actor{wxId,nickname,avatarUrl}`, `preview`, `read`, `createdAt`。
- 未读计数：响应 `unreadCount` 或单独字段供 Tab badge（MVP 可列表 filter）。

### 7. Flutter「互动消息」

- `UcgMessagesTab`：会话列表上方（或独立 section）展示「互动消息」入口/内嵌列表。
- Provider `ucgCommentNotificationsProvider` 分页拉取；点击 → `Navigator.push(UcgPostDetailScreen(postId: …))`。
- 进入列表或点击项 → `POST …/read`。
- Tab 红点：会话未读 **或** 互动消息未读（叠加逻辑与产品确认：MVP 互动消息未读显示 section badge）。

### 8. WebSocket 推送（可选）

- ucg-service 在 insert notification 后向在线 recipient 推送 WS 帧：`{ "type": "comment_notification", "notificationId": … }`。
- Flutter WS 客户端监听并 `invalidate` notifications provider。
- **MVP 可仅 REST 拉取**；design 保留扩展点，tasks 中标记 optional。

### 9. @ 提及格式

- 客户端长按评论预填 `@${comment.authorNickname} `（尾部空格）。
- 服务端解析：优先匹配 `@([\u4e00-\u9fa5\w]+)` 再查 nickname→wxId（ucg profile 表）；歧义时通知第一个匹配或跳过（document in Open Questions）。
- **不**发 DM（Option A 硬约束）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 详情全量评论/点赞性能 | 初期帖子量小可全量；后续可加 cursor 分页但 UI 仍不折叠 |
| nickname @ 解析歧义 | 文档约定；后续可改 `@wxId:123` 精确格式 |
| 双列 + 视频高度抖动 | 固定 video tile max height；首帧 poster 占位 |
| 旧客户端无 notification API | 新字段 optional；旧版忽略互动消息 section |
| 后端先于 Flutter 部署 | Feed bio fallback 向后兼容；`GET /posts/{id}` 新端点不影响旧客户端 |

## Migration Plan

1. **go_ai_talk**：DB migration `ucg_notification` → 实现 notification repo + REST → 扩展 AddComment hook → 实现 `GET /posts/{id}` + Feed bio enrichment → gateway 白名单 → 部署 ucg-service + gateway。
2. **Flutter**：依赖 `flutter_staggered_grid_view` → models/repository → 广场/详情 UI → 互动消息 Tab → 联调。
3. **回滚**：保留 Feed 列表路径；新 UI feature flag 可选（非必须）；通知表可停用 hook 不写新行。

## Open Questions

- @ 提及 nickname 重名时通知策略：MVP 建议跳过无法唯一解析的 @，仅记录 comment_on_post。
- 互动消息未读是否与聊天未读合并为同一 Tab 红点：建议 OR 合并，section 内再分 unread。
- WS `comment_notification` 是否纳入 MVP tasks：标记 optional，REST 为必须。
