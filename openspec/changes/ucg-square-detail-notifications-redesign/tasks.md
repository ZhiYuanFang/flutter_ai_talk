## 1. 后端 go_ai_talk — 数据与单帖 API

- [x] 1.1 新增 `ucg_notification` 表 migration（recipient、type、post_id、comment_id、actor、preview、read_at、created_at）— `ucg-notifications`
- [x] 1.2 实现 notification repository（insert、paginated list by recipient、mark read by ids/all）— `ucg-notifications`
- [x] 1.3 实现 `GET /posts/{id}` handler：已发布帖可读、author enrichment、`likedByMe`（已登录 wxId）— `ucg-api-contract`
- [x] 1.4 Feed mapper：`author.bio` 空时 `GetPublicProfile` fallback — `ucg-api-contract` / `ucg-profile`
- [x] 1.5 gateway-app：白名单注册 `GET /posts/{id}`（匿名可读已发布帖，与现有 UCG 策略一致）— `ucg-api-contract`

## 2. 后端 go_ai_talk — 评论通知 API 与 Hook

- [x] 2.1 实现 `GET /notifications/comments` 分页列表 + actor profile enrichment + `unreadCount` — `ucg-notifications`
- [x] 2.2 实现 `POST /notifications/comments/read`（ids / all）— `ucg-notifications`
- [x] 2.3 AddComment 成功后 hook：通知帖子作者（跳过自己）— `ucg-notifications`
- [x] 2.4 解析评论 `@mentions` → 写入 `mention_in_comment`（去重、跳过评论者；**不得** CreateConversation / 发 DM，Option A）— `ucg-notifications`
- [x] 2.5 （可选）insert 后 WS 推送 `comment_notification` 帧 — `ucg-notifications` / design §8

## 3. Flutter — 模型与 Repository

- [x] 3.1 `pubspec.yaml` 添加 `flutter_staggered_grid_view` 依赖
- [x] 3.2 `UcgPost` / author DTO 增加 `authorBio` 解析 — `ucg-api-contract`
- [x] 3.3 `UcgRepository.fetchPost(id)` → `GET /posts/{id}` — `ucg-api-contract`
- [x] 3.4 新增 `UcgCommentNotification` model + `fetchCommentNotifications` / `markNotificationsRead` — `ucg-notifications`
- [x] 3.5 Riverpod providers：`ucgPostDetailProvider`、`ucgCommentNotificationsProvider` — `ucg-notifications`

## 4. Flutter — 广场 Feed 双列重构

- [x] 4.1 `UcgSquareTab`：移除 title/subtitle；顶栏 inline 推荐/关注 Tab（无背景盒）— `ucg-square-feed`
- [x] 4.2 用 `MasonryGridView` 替换单列 ListView；分页 append — `ucg-square-feed`
- [x] 4.3 新 Feed 卡片 widget：头像、昵称、authorBio maxLines:2、媒体、时间；**无** liker 预览、**无**「···」、**无**内联评论 — `ucg-square-feed`
- [x] 4.4 卡片心形右下 enlarged tap → like/unlike + `likedByMe` — `ucg-interactions`
- [x] 4.5 卡片 tap → 详情；图片 tap → lightbox（保留 `UcgMediaViewer` 行为）— `ucg-square-feed`

## 5. Flutter — 沉浸式详情页

- [x] 5.1 重构 `UcgPostDetailScreen`：无 AppBar、模糊背景、无圆角卡片容器 — `ucg-interactions`
- [x] 5.2 顶栏：返回 + 头像 + 昵称 + 关注/已关注 pill 样式 — `ucg-interactions`
- [x] 5.3 全文 authorBio；时间行右「···」→ Like/Comment pill — `ucg-profile` / `ucg-interactions`
- [x] 5.4 点赞区：心形 + 全量 liker 头像网格、无 count；心形与首行头像垂直居中 — `ucg-interactions`
- [x] 5.5 评论全量列表、无标题/折叠；长按评论 → 输入框 `@nickname ` 预填 — `ucg-interactions`
- [x] 5.6 作者可见删除 → `DELETE /posts/{id}`；进入时 `fetchPost` refresh — `ucg-interactions`
- [x] 5.7 广场与「我的动态」统一路由至同一详情页 — `ucg-profile`

## 6. Flutter — 我的动态与消息 Tab

- [x] 6.1 「我的动态」图片/行点击 → 详情（**禁止** lightbox）— `ucg-profile`
- [x] 6.2 `UcgMessagesTab` 增加「互动消息」section UI — `ucg-chat-ui` **（首版 flat 列表；§8 改为虚拟系统行 + Inbox 页）**
- [x] 6.3 互动消息列表分页、点击 → `UcgPostDetailScreen(postId)` — `ucg-chat-ui` **（§8 迁移至 Inbox 页）**
- [x] 6.4 查看/点击时调用 mark read；消息 Tab 红点合并会话与互动未读 — `ucg-chat-ui` **（§8 改为 Shell 级红点 + Inbox「全部已读」）**
- [x] 6.5 WS 监听 `comment_notification` → invalidate provider — design §10 **（§8 改为 Shell 级 WS）**

## 7. 联调与验收

- [ ] 7.1 部署 ucg-service + gateway 后验证：`GET /posts/{id}`、`GET /notifications/comments`、AddComment 写通知
- [ ] 7.2 手工路径：广场双列 → 详情 → 评论/@ → 被 @ 用户「互动消息」→ 详情（**无**自动 DM）
- [ ] 7.3 手工路径：我的动态图片进详情；广场图片 lightbox；Feed 心形点赞不跳详情
- [ ] 7.4 确认 Feed 卡片展示 authorBio（2 行）；详情全文 bio

### 7.x 反馈修复（2026-06-08）

- [x] **Masonry 卡片容器**：`UcgMasonryFeedCard` 外包 `UcgShellGlassCard`（padding 10、radius 12），双列每项独立玻璃卡片。
- [x] **@mention 通知**：根因是服务端仅按 `@昵称` 精确查 profile，重名/特殊字符/默认「家长」等导致 `resolveNicknameToWxID` 返回 0。修复：长按评论预填 `@昵称#wxId`；服务端解析 `#wxId` 直查、纯数字 `@wxId`、放宽昵称字符集；详情评论展示时隐藏 `#wxId` 后缀。
- [x] **Feed 列表点赞只读**：双列卡片移除 tap-to-like；`likeCount > 0` 时时间行右侧展示「计数 + 心形」（`likedByMe` 为实心、与时间同色；实心/描边同尺寸 `22 * 2 / 3`）；`likeCount == 0` 隐藏；点赞/取消仅在详情页。
- [x] **详情删除入口**：自己的动态移除顶栏删除 IconButton；删除移入时间行 `···` 展开菜单，图标样式与点赞/评论一致（`delete_outline_rounded`，`fg @ 0.75`）。
- [x] **详情互动跳转**：点赞头像、评论昵称点击跳转 `UcgUserProfileScreen`；评论长按仍 @ 回复。
- 7.1–7.4 仍需部署后手工验收（含 @mention 端到端；7.3 Feed 心形改为只读展示，点赞在详情页操作）。

## 8. 互动消息 Inbox 重做 + 通知封面快照（2026-06-08 rework）

> **Supersedes** tasks 6.2–6.5 的 flat section / Tab-gated WS 行为；首版已落地代码需 refactor。

### 8.1 后端 — 通知封面快照

- [x] 8.1.1 Migration `ALTER ucg_notification ADD post_thumb_url VARCHAR(512) NOT NULL DEFAULT ''`, `ADD post_media_kind TINYINT NOT NULL DEFAULT 0` — `ucg-notifications`
- [x] 8.1.2 实现 `BuildVideoSnapshotURL(objectKey)`（CDN + `x-oss-process=video/snapshot,t_0`）— `ucg-notifications` / design §6
- [x] 8.1.3 `NotifyOnComment`：每条 comment **一次** `loadPostMedia` → 首媒体 snapshot → 传入 `InsertNotification` — `ucg-notifications`
- [x] 8.1.4 `NotificationDTO` / OpenAPI item 增加 `postThumbUrl`, `postMediaKind`；`ListCommentNotifications` **不得** batch enrich 帖子 — `ucg-api-contract`
- [ ] 8.1.5 回归：视频帖 comment 通知行 `postThumbUrl` 为 OSS snapshot URL（非空 placeholder）

### 8.2 Flutter — 虚拟系统行 + Inbox 页

- [x] 8.2.1 `UcgCommentNotification` model 增加 `postThumbUrl`, `postMediaKind` 解析 — `ucg-api-contract`
- [x] 8.2.2 移除 `UcgMessagesTab` flat「互动消息」section；改为置顶 **虚拟系统会话行**（未读角标、固定文案）— `ucg-chat-ui`
- [x] 8.2.3 新增 `UcgInteractionInboxScreen`：AppBar「全部已读」→ `{ all: true }`；列表行 avatar + nickname + 2-line preview + 方形 `postThumbUrl`；分页 load more — `ucg-chat-ui`
- [x] 8.2.4 Inbox 点击行 → `UcgPostDetailScreen`；单条 mark read — `ucg-chat-ui`
- [x] 8.2.5 `ucgCommentNotificationsProvider` 支持 inbox 分页 append；conversations 列表分页（若缺失则补）— `ucg-chat-ui`
- [x] 8.2.6 `UcgShell` mount 时 `setWsConnectionDesired(true)` + 监听 `comment_notification`；移除 `UcgMessagesTab` / Tab tap WS toggle — `ucg-shell-navigation`
- [x] 8.2.7 Shell 底部「消息」红点 = chat unread OR interaction unread（任意 Tab 可见）— `ucg-shell-navigation`

### 8.3 Flutter — Composer @ 展示层

- [x] 8.3.1 详情评论 Composer：展示 `@昵称`、提交 `@昵称#wxId`（已有 wire 保持）— `ucg-interactions`
- [x] 8.3.2 @ mention 高亮（TextSpan / 主题色）— `ucg-interactions`
- [x] 8.3.3 Backspace 原子删除整段 `@昵称#wxId`（含尾空格）— `ucg-interactions`

### 8.4 验收

- [ ] 8.4.1 视频帖被 comment/@ → Inbox 右侧缩略图为 OSS video snapshot（非 placeholder）
- [ ] 8.4.2 消息 Tab 仅见系统行 + 私信；点击进入 Inbox；「全部已读」清空未读 + Shell 红点消失
- [ ] 8.4.3 非消息 Tab 时收到 WS `comment_notification` → Shell 红点更新
- [x] 8.4.4 Composer：输入框见 `@昵称` 高亮，提交 payload 含 `#wxId`，Backspace 一次删整段 mention

## 9. 评论长按分支 + 禁止 @ 自己（2026-06-08）

- [x] 9.1 长按他人评论 → @ 回复；长按本人评论 → 评论上方删除图标（点图标即删，无二次确认）— `ucg-interactions`
- [x] 9.2 `DELETE /comments/{id}` 删除后本地列表与 commentCount 更新 — `ucg-interactions`
- [x] 9.3 发送评论时 strip 对当前 wxId 的 @ mention（不允许 @ 自己）— `ucg-interactions`
