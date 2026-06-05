## Context

当前 `/home` 路由直接渲染 `HomeScreen`（`app/lib/ui/home_screen.dart`），承载喂养记录、事件录入、AI 对话与 history WebSocket（`RemoteFeedRepository`，`app/lib/data/remote_feed_repository.dart`）。路由与鉴权由 `go_router` + `sessionProvider`（`app/lib/router/app_router.dart`）统一管理：公开页可匿名，业务页未登录重定向 `/login`。

UCG 模块需在**不破坏喂养页行为**的前提下，增加第二屏社区能力，并对接后端 `ucg-service`：**HTTP 与聊天 WebSocket 均经 gateway-app 同域暴露**（`/ucg/app/api/*` 与 `/ucg/app/ws/chat`），与 history WS 使用相同 `apiBaseUrl` host 推导模式。

## Goals / Non-Goals

**Goals:**

- PageView 双页：page 0 = 现有 `HomeScreen`；page 1 = UCG 壳（五栏导航）。
- 喂养页右侧「进入广场」可展开拉条，点击进入 UCG；UCG 页隐藏拉条；支持手势滑动切换（可选，至少支持拉条点击）。
- 广场（关注/推荐）、发布、消息、我的完整 MVP UI；宝藏占位。
- 推荐 Feed 未登录可浏览；关注/发帖/消息/资料编辑需登录（局部 gate，不全局改 redirect）。
- 媒体展示 URL：`https://resorce.cuplay.top/{objectKey}`。
- 发布草稿本地持久化；与「我的动态」编辑共用 compose。
- 聊天 WS 客户端参考 `RemoteFeedRepository`（auth 首帧、重连、生命周期）；URL 由 `AppEnv.apiBaseUrl` 推导 `/ucg/app/ws/chat`（同 `wsHistoryUrlEffective` 模式）。
- UCG 视觉与喂养模块统一：主题色受 `AppVisualTokens` + `ColorScheme.primary` 控制；玻璃拟态复用现有组件；沉浸式布局，禁止 TabBar/AppBar 与内容区背景割裂。

**Non-Goals:**

- 宝藏业务、拉黑/举报、群聊、@提及、分享卡片到微信。
- 直连 ucg-service 公网地址或独立 UCG WS 域名配置（无 `UCG_WS_URL` 直连 env）。
- 修改全局 `go_router` redirect 允许匿名访问 `/home`（喂养仍可按现有规则；UCG 推荐在页内 gate）。

## Decisions

### 1. 入口容器：`UcgHomeShell` 包裹 PageView

**Decision**：新增 `UcgHomeShell`（或等价命名）作为 `/home` 的 root widget；`PageController` 管理 0/1 两页；page 0 保留现有 `HomeScreen` 子树（尽量不改其 State 逻辑）。

**Why**：最小侵入喂养代码；PageView 与产品「左喂养、右广场」一致。

**Alternatives**：独立 `/ucg` 路由 — 丢失横向滑动手势与拉条联动；TabBar 嵌套 — 与「全屏 UCG 壳」不符。

### 2. 右侧拉条：仅 page 0 显示，仿悬浮球 expandable strip

**Decision**：`Positioned` 右侧边缘组件，默认窄条露出「进入广场」；可横向拖出/点击；`onTap` → `PageController.animateTo(1)`。page 1 时 `Offstage` 或条件不 build。

**Why**：产品指定仅在喂养页出现；与现有 overlay 模式（如 fly overlay）一致。

### 3. UCG 壳：IndexedStack + BottomNavigationBar

**Decision**：UCG page 内用 `IndexedStack` 保持五 Tab 状态；Tab：广场(0)、宝藏(1)、+(2 打开全屏 compose route/sheet)、消息(3)、我的(4)。`+` 不占 stack index，用 `FloatingActionButton` 或 BottomBar 中间凸起按钮。

**Why**：IndexedStack 避免切换 Tab 丢滚动位置；与微信/小红书底部栏模式一致。

### 4. 路由与深链

**Decision**：UCG 内部导航优先壳内 Tab + 局部 `Navigator`（或 `go_router` 子路由 `/home/ucg/...` 可选）；MVP 可用壳内 `Navigator.push` 打开聊天页、compose、资料编辑，避免大规模改 `app_router.dart`。

**Why**：降低 Phase 1 路由 refactor 风险；后续可再收敛到 go_router 子树。

### 5. HTTP：复用 `ApiClient` + gateway 前缀

**Decision**：新增 `UcgApiClient` 或扩展 `ApiClient` 方法，base path `/ucg/app/api`；分页 query `page`、`pageSize`（与现有 history 列表一致）。Bearer 由现有 session 注入。

**Env**：HTTP 与现有 App API 共用 `AppEnv.apiBaseUrl`；无需独立 UCG HTTP base URL。

### 6. WebSocket：新建 `UcgChatRepository`

**Decision**：参考 `RemoteFeedRepository` 实现：连接、JWT auth 首帧、ping/pong、断线重连、未读事件 stream。HTTP 拉历史/会话列表，WS 收实时消息与 audit 结果。

**URL 推导**（镜像 `wsHistoryUrlEffective`，`app/lib/config/env.dart`）：

- 可选 override：`WS_UCG_CHAT_URL`（`--dart-define`，对应 `wsUcgChatUrl`）
- 默认：`wsUcgChatUrlEffective` 由 `apiBaseUrl` 推导 `wss://{host}[:port]/ucg/app/ws/chat`（含 path 前缀，scheme `https`→`wss`）

**Why**：与 history WS、UCG HTTP 同域；gateway 统一 TLS 终止；运维无需单独暴露 ucg-service WS 端口。

### 7. 登录门控策略

**Decision**：

| 能力 | 未登录 |
|------|--------|
| 推荐 Feed 浏览 | 允许 |
| 关注 Feed | 引导登录 |
| 点赞/评论/发帖/消息/编辑资料 | 引导登录 |
| 查看他人 profile 基础信息 | 允许（与 API 一致） |

实现：`ref.read(sessionProvider).isLoggedIn` + 统一 `requireUcgLogin(context)` 跳转 `/login?return=...`。

### 8. Compose 草稿

**Decision**：`SharedPreferences` 或项目现有 KV（若已有）存 JSON：`text`、`objectKeys[]`、`videoKey`、`updatedAt`；进入 compose 时 restore；发布成功或用户清草稿时 delete。

### 9. 帖子/消息媒体状态 UI

**Decision**：列表项根据 `status` 展示：他人仅见 `published`；作者见 `pending_audit`（「审核中」）、`rejected`（「违规已下架」+ reason）、`draft`（仅我的动态）。

### 10. CDN URL 拼装

**Decision**：集中 `UcgMediaUrl.objectKeyToCdn(String key) => 'https://resorce.cuplay.top/$key'`；DTO 只含 objectKey。

### 11. 视觉系统：与喂养模块一致的主题 + 玻璃拟态 + 沉浸式布局

**Decision**：UCG 全部页面 MUST 继承现有 `AppThemeScope` / `AppVisualTokens` 主题链，不得引入独立 UCG 色板或硬编码品牌色。

| 语义 | 喂养模块参考 | UCG 用法 |
|------|-------------|----------|
| 页面背景 | `HomeScreen` → `tokens.shellColor` | UCG 壳、广场、我的、消息列表根 `Scaffold.backgroundColor` |
| 主题色/强调色 | `ColorScheme.primary`、`themePrimaryBlend(context)` | 选中 Tab、按钮、链接、未读点、互动高亮 |
| 卡片/面板 | `recordsCardColor` / `themePrimaryBlend(alpha: 0.14)` | Feed 卡片、会话行、资料区块 |
| 玻璃容器 | `HistoryEditGlassPanel`、`showGlassAdaptiveBottomSheet`、`showGlassDialog` | 底部 Sheet、确认框、发布/编辑弹层 |
| 沉浸式顶栏 | `HomeImmersiveHeader`（无 AppBar 色块） | UCG 各 Tab 顶区标题/返回，与内容共享 shell 背景 |

**子 Tab（广场 关注/推荐）**：MUST NOT 使用 Material 默认 `TabBar` + 独立 `AppBar` 造成顶栏与列表背景分层。采用**内容区内嵌** segmented pill（`pillBackground` / `pillBorder` + `primary` 选中态），与 Feed 列表同属一层 `Column`，背景连续为 `shellColor`。

**底部五栏导航**：MUST NOT 使用带 elevation 的默认 `BottomNavigationBar` 色块条。采用悬浮玻璃 dock（`BackdropFilter` + `tokens.surfaceColor` 半透明 + 圆角 pill），与 `HomeInputModeDock` 同级视觉语言；选中项用 `ColorScheme.primary`。

**禁止样式（Anti-patterns）**：
- 顶部 TabBar 白/灰底 + 下方内容另一底色（「头身分离」）
- 独立 `AppBar` 与 `Scaffold` 背景色不一致
- UCG 内新建一套与 `AppVisualTokens` 无关的固定 hex 色（Sheet 内 `HistoryEditGlassPanel` 固定前景色除外）

**Why**：产品要求 UCG 与喂养同属胖宝视觉体系；用户已明确拒绝割裂 TabBar 样式。

**Alternatives**：各 Tab 独立 `AppBar` + `TabBar` — 与喂养沉浸式风格冲突；纯 Material 3 默认组件 — 无玻璃拟态与主题联动。

## Risks / Trade-offs

- **[Risk] PageView 与 HomeScreen 手势冲突（横向滑动 vs 时间轴）** → PageView 仅边缘拉条触发切换，或 `NeverScrollableScrollPhysics` + 仅拉条/按钮切换。
- **[Risk] 双 WebSocket（history + ucg）耗电与连接数** → UCG WS 仅在消息 Tab active 或存在未读时保持连接；离开 UCG 页可降级断开。
- **[Risk] 未登录浏览推荐与 API 匿名策略不一致** → 与后端 `ucg-app-http-api` 对齐，推荐接口加入 gateway 白名单或 optional auth。
- **[Risk] compose 大视频内存** → 客户端压缩/限制 15s/20MB 后再上传；超限 toast。

## Migration Plan

1. Phase 1：壳 + 广场只读 + profile 只读（对接 backend Phase 1–2）。
2. Phase 2：compose + 草稿 + 我的动态。
3. Phase 3：审核状态 UI。
4. Phase 4：互动 + 关注 Tab。
5. Phase 5：消息 + WS（经 gateway `/ucg/app/ws/chat`）。
6. Phase 6：动画 polish、推荐刷新策略。

回滚：feature flag 或 revert `UcgHomeShell`，`/home` 恢复单 `HomeScreen`。

## Open Questions

- 视频选择是否复用现有相机/相册插件，取决于 `pubspec` 现有依赖。
