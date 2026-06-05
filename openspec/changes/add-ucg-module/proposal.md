## Why

胖宝 App 当前以喂养记录与 AI 对话为核心，缺少家长之间的内容分享与私信能力。引入 UCG（用户生成内容）模块可让家长在记录育儿日常的同时浏览推荐动态、关注他人、发布图文/短视频，并进行一对一聊天，提升留存与社区价值。

该变更需与后端新建的 `ucg-service` 同步推进：Flutter 端负责沉浸式入口（喂养页 PageView + 右侧「进入广场」拉条）、UCG 五栏壳层、广场/宝藏/发布/消息/我的全链路 UI，以及经 **gateway-app 同域** 的 HTTP（`/ucg/app/api/*`）与 WebSocket（`/ucg/app/ws/chat`）。

## What Changes

- **入口与壳层**：`/home` 由单一 `HomeScreen` 改为 `PageView`（page 0 = 现有喂养 `HomeScreen`，page 1 = UCG 壳）；仅在喂养页显示右侧可展开拉条「进入广场」，点击滑至 UCG；UCG 页隐藏拉条。
- **底部导航**：UCG 壳内五栏——广场、宝藏、+（发布）、消息、我的。
- **广场**：Tab「关注」「推荐」；分页列表；微信朋友圈风格卡片；未登录可浏览推荐，关注 Tab 与互动需登录。
- **宝藏**：占位页「尚未开通」。
- **发布（+）**：图文（≤9 张）或单视频（≤15s / 20MB）；本地草稿保存与恢复；与「我的动态」编辑共用 compose 流程。
- **消息**：会话列表（微信风格，左滑置顶/删除）；1:1 聊天（文本/图片/视频）；WebSocket 经 **gateway-app** `/ucg/app/ws/chat`（与 HTTP 同 `apiBaseUrl` host）；未读红点。
- **我的**：小红书风格个人页（可编辑头像/昵称/简介、关注列表、我的动态、我的宝藏占位）。
- **互动 MVP**：点赞、评论、删除自己的评论、长按撤销自己的点赞；无拉黑/举报。
- **鉴权**：推荐流可匿名浏览；关注、发帖、消息、个人资料编辑等需登录（复用现有 `sessionProvider` + `go_router` redirect 策略的局部门控）。
- **媒体 CDN**：展示 URL 为 `https://resorce.cuplay.top/{objectKey}`；客户端只存/传 `objectKey`。
- **技术栈**：延续 `go_router` + Riverpod；HTTP 与 WS 均经 gateway 同域；WS 参考 `RemoteFeedRepository` + `wsHistoryUrlEffective` 模式新建 `UcgChatRepository`。
- **视觉与主题**：UCG 全模块 UI **必须与喂养模块一致**——复用 `AppVisualTokens` / `ColorScheme.primary` / `themePrimaryBlend` 主题色体系；卡片、Sheet、底部栏采用与喂养页相同的**玻璃拟态**（`HistoryEditGlassPanel`、`app_glass_overlay`）；**禁止**顶部 TabBar 与下方内容区背景/色块割裂的「双栏分层」样式，子 Tab（如广场关注/推荐）须沉浸式嵌入同一 `shellColor` 背景。
- **BREAKING**：`/home` 根 widget 结构变更（由单页变为 PageView 容器），需回归喂养页全部交互与生命周期。

## Capabilities

### New Capabilities

- `ucg-home-entry`：PageView 双页入口、右侧「进入广场」拉条与页面切换行为。
- `ucg-shell-navigation`：UCG 五栏底部导航与 Tab 路由状态。
- `ucg-square-feed`：广场关注/推荐分页 Feed、卡片 UI 与登录门控。
- `ucg-compose-post`：发布页、媒体选择与限制、本地草稿持久化及与编辑共用。
- `ucg-profile`：我的页、资料编辑、关注列表、我的动态列表。
- `ucg-chat-ui`：消息 Tab、会话列表、1:1 聊天 UI、未读红点、经 gateway 的 WS 客户端。
- `ucg-interactions`：点赞、评论、删评、长按撤销点赞。
- `ucg-media-cdn`：objectKey 与 CDN URL 拼装约定。
- `ucg-visual-system`：与喂养模块一致的主题色、玻璃拟态组件复用、沉浸式布局（无割裂 TabBar/AppBar）。

### Modified Capabilities

- 无（`openspec/specs/v1.0.1.md` 为版本说明，非独立能力基线；本变更为全新 UCG 能力集）。

## Impact

- **Affected code**：`app/lib/ui/home_screen.dart`（或拆出 `UcgHomeShell`）、`app/lib/router/app_router.dart`、`app/lib/providers/repositories.dart`、新增 `app/lib/ucg/**` 模块（data/providers/ui）。
- **API 依赖**：gateway `GET/POST /ucg/app/api/*`（profile、feed、posts、media presign、follow、conversations）；gateway WebSocket `/ucg/app/ws/chat`（与 `AppEnv.apiBaseUrl` 同 host，由 `wsUcgChatUrlEffective` 推导）。
- **本地存储**：compose 草稿（SharedPreferences 或现有本地 KV 模式）。
- **Dependencies**：无新增 major 包预期；复用现有 `web_socket_channel`、图片/视频选择器（按项目现有选型）。
- **Systems**：与 `go_ai_talk` 中 `ucg-service`、`gateway-app` UCG HTTP/WS 代理同步上线；Green 审核状态驱动 Feed 可见性（作者见 pending/rejected 文案）。
