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
- [x] 6.2 `UcgMessagesTab` 增加「互动消息」section UI — `ucg-chat-ui`
- [x] 6.3 互动消息列表分页、点击 → `UcgPostDetailScreen(postId)` — `ucg-chat-ui`
- [x] 6.4 查看/点击时调用 mark read；消息 Tab 红点合并会话与互动未读 — `ucg-chat-ui`
- [x] 6.5 （可选）WS 监听 `comment_notification` → invalidate provider — design §8

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
