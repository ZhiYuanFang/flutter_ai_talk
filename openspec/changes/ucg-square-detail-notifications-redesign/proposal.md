## Why

当前 UCG 广场仍沿用微信朋友圈式单列卡片（内联评论、灰底点赞块、右下角「···」菜单），与产品目标的小红书式双列瀑布流及沉浸式详情页不一致；Feed 卡片缺少作者简介、详情页缺少单帖拉取与 `likedByMe` 富化，且评论/@ 提及无法通过「互动消息」触达被提及用户。需要在 Flutter 与 `go_ai_talk` 同步落地广场/详情 UI 重构，并新增评论通知能力（@ 提及仅 inbox 通知，不自动发私信）。

## What Changes

### 广场 Feed（**BREAKING** UI）

- 移除页面标题/副标题；**推荐 / 关注** Tab 置于顶栏位置，无 Tab 背景盒（inline segmented，遵循 `ucg-visual-system`）。
- 双列 masonry 瀑布流（`flutter_staggered_grid_view`）；卡片移除点赞者头像预览、移除「···」菜单、移除内联评论预览。
- 卡片点击 → 帖子详情；右下角心形 → 点赞/取消赞（更大点击区域）；图片点击 → lightbox；昵称下方展示作者 `bio`（最多 2 行）。
- Feed 上评论仅能从详情页进入（无卡片内联评论）。

### 沉浸式详情页（**BREAKING** UI）

- 移除 AppBar/TabBar chrome；模糊背景（主题色 / 首图 / 视频封面）；无卡片圆角背景。
- 顶栏：返回 + 头像 + 昵称 + 关注 pill（「关注」/「已关注」不同样式）；作者 `bio` 全文展示（不截断）。
- 时间行右对齐「···」→ 浮层 Like/Comment；点赞区：心形 + 点赞者头像网格，**不展示数量**；心形反映当前用户 `likedByMe`；与首行头像垂直居中。
- 评论区：无标题/计数头；长按评论 → 输入框预填 `@nickname`；点赞与评论列表**不折叠**。
- 仅作者可见删除按钮；广场 Feed 与「我的动态」共用同一详情页实现。

### 我的动态（行为差异）

- 图片点击 → 进入详情页（**非** lightbox）；广场 Feed 仍保持图片 tap → lightbox。

### 后端 go_ai_talk（**不得跳过**）

- 新增 `GET /posts/{id}`，返回单帖并 enrichment `likedByMe`；gateway 白名单。
- Feed 列表 `author.bio` 必须始终有值（帖子快照缺失时 profile fallback）。
- 新增 `ucg_notification` 表及评论通知 API。
- `AddComment` hook：通知帖子作者（跳过自己）；解析 `@mentions` → 通知被 @ 用户（**Option A**：仅「互动消息」inbox，**不**自动创建 DM）。
- `GET /notifications/comments`（分页）、标记已读 API。

### Flutter 客户端

- 解析 `authorBio`；`fetchPost`；masonry 布局。
- 消息 Tab 新增「互动消息」区块 → 评论通知列表 → 点击跳转帖子详情。
- WebSocket 推送 `comment_notification`（可选，见 design.md）。

## Capabilities

### New Capabilities

- `ucg-notifications`：评论与 @ 提及的 inbox 通知存储、列表、已读、AddComment 触发规则（Option A：仅通知，不自动 DM）。

### Modified Capabilities

- `ucg-square-feed`：双列 masonry、精简卡片交互、Feed 作者 bio、图片 lightbox vs 详情路由差异。
- `ucg-interactions`：详情页点赞/评论 UX、长按回复 @、全量点赞评论展示、Feed 卡片心形点赞。
- `ucg-api-contract`：`GET /posts/{id}`、`likedByMe` enrichment、Feed `author.bio` fallback、评论通知 REST 契约。
- `ucg-chat-ui`：消息 Tab「互动消息」区块与通知列表导航。
- `ucg-profile`：Feed/详情展示作者 bio（列表 2 行截断、详情全文）。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_square_tab.dart`、`ucg_post_detail_screen.dart`、`ucg_feed_moments_widgets.dart`、`ucg_messages_tab.dart`、`ucg_repository.dart`、`ucg_models.dart`；新增 `flutter_staggered_grid_view` 依赖。
- **后端**：`d:\work\go_ai_talk` ucg-service（posts handler、notification service/migration、AddComment hook）；gateway-app 路由白名单与可选 WS 帧。
- **OpenSpec**：本变更 delta 覆盖 `unify-ucg-wxid-api-alignment` 中 Moments 单列/内联互动相关条款；与之并行时以本变更 Feed/详情/通知需求为准。
- **部署顺序**：先后端（表迁移 + API）再 Flutter；旧客户端在无 `GET /posts/{id}` 时仍可依赖 Feed 项进入详情（降级策略见 design.md）。
