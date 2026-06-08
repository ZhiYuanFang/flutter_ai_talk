## Context

- **现状**：`50a5bd5`（初代）引入 `ColdStartBootstrap` 未登录 → `/login`，以及 `go_router` 全局 `if (!session.isLoggedIn) return '/login'`，与 init 阶段「Splash 始终 `go('/home')`」及 v1.0.1「默认进入主页」不一致。
- **UCG 层**：推荐 Feed、帖子详情、他人主页已支持匿名或弱鉴权浏览；`UcgShell` 对消息/我的展示整页 `UcgLoginPrompt`；关注 Tab 对游客展示登录引导而非发现空态。
- **喂养层**：`HomeScreen._ensureRemoteGate()` 已用 `showGlassConfirmDialog` 拦截语音/发送，无需大改。
- **国行 iOS**：系统「无线局域网与蜂窝网络」授权无 API 主动申请，仅能在真实 outbound 请求时触发；OpenSpec 要求 Splash 不得 await 远程任务。

## Goals / Non-Goals

**Goals:**

- 未登录冷启动进入 `/home`，可浏览喂养主页与 UCG 推荐广场。
- 个人信息相关入口（消息、我的、发布）与互动操作（点赞、评论、关注）在触发时用弹窗引导登录。
- 关注 Tab：游客可切换；未登录或关注列表为空时展示统一文案空态，不调 following API（游客）或展示 API 空结果（已登录）。
- iOS 首次安装旁路发起一次轻量 GET，不阻塞冷启动、不处理响应。

**Non-Goals:**

- 修改后端鉴权或新增 `/health` 接口。
- 区分国行/非国行设备（probe 仅按 `Platform.isIOS`）。
- 检测用户是否已授予无线数据权限（iOS 无回调 API）。
- 修改登录页 UI 或微信/Apple 登录流程。

## Decisions

### 1. 冷启动目标路由恒为 `/home`

**Decision**：`ColdStartBootstrap.run` 返回 `route: '/home'`，移除 `session.isLoggedIn ? '/home' : '/login'` 分支。

**Why**：与 v1.0.1「默认进入主页」及 UCG 游客浏览一致；登录页仅通过用户主动操作或 gate 跳转进入。

**Alternatives**：未登录先进 UCG 广场 — 产品默认仍是喂养主页 PageView index 0。

### 2. Router 白名单 + 敏感子路由黑名单

**Decision**：`redirect` 中 `public` 集合扩展为包含 `/home`、`/trends`、`/settings`；对 `/settings/bind-baby`、`/settings/change-password`、`/settings/feedback` 等保持 `!isLoggedIn → /login`。

**Why**：设置页规格允许游客打开（宝宝信息占位）；绑定/改密/反馈属账号能力需登录。

**Alternatives**：全局放开所有 `/settings/*` — 会暴露绑定与反馈路由，不安全。

### 3. UCG Dock：Tab 点击前弹窗，不切 Tab

**Decision**：在 `UcgShell._onTabTap` 中，index `2`（发布）、`3`（消息）、`4`（我的）在 `!isLoggedIn` 时调用统一 `promptLoginForPersonalAction`（玻璃确认弹窗），用户确认后 `push('/login')`，`return` 不更新 `_tabIndex`。

**Why**：符合产品「点个人入口才提示」；避免切 Tab 后整页占位造成上下文丢失。

**Alternatives**：保留整页 `UcgLoginPrompt` — 与产品最新决策不符。

### 4. `requireUcgLogin` 对齐玻璃弹窗

**Decision**：将 `requireUcgLogin` 改为先 `showGlassConfirmDialog`（标题「需要登录」，确认「去登录」），确认后再 `push('/login')`；供点赞、评论、关注等复用。

**Why**：与喂养 `_ensureRemoteGate` 体验一致。

### 5. 关注 Tab 统一空态组件

**Decision**：抽取关注空态常量或私有 widget：

- `title`: `还没有关注的人`
- `subtitle`: `去推荐看看，点击动态中的头像进入主页，关注你感兴趣的人`
- 无 `action` 按钮

游客关注：`body` 直接渲染该空态，不经过 `_buildBody` 的推荐 `_items`；已登录关注 Feed 空：`_buildBody` 在 `_mode == following && _initialLoaded && _items.isEmpty` 时渲染同一空态。

**Why**：避免游客切关注时短暂展示推荐流缓存；文案统一且无按钮。

### 6. iOS 网络探测旁路模块

**Decision**：新增 `IosNetworkPermissionProbe.run()`：

- 条件：`Platform.isIOS && !kIsWeb`
- 标记：`SharedPreferences` key `ios_network_probe_attempted`（请求前写入，避免双发）
- 请求：`GET ${AppEnv.apiBaseUrl}/device/app/api/version/check?currentVersion=0.0.0`，`withAuthorization: false`，`timeout` 5s，`catchError` 吞掉
- 调用：`PangbaoApp._beginStartupIfNeeded` 内 `unawaited(IosNetworkPermissionProbe.run())`，与 `_runColdStart` 并行

**Why**：复用已有无鉴权接口；不阻塞 Splash；与 UCG 推荐请求可叠加触发授权，probe 保证尽早出站。

**Alternatives**：`HEAD` 基址 — 网关可能不支持；仅依赖 UCG Feed — 游客可能不进广场。

## Risks / Trade-offs

- **[Risk] 用户选「不允许」无线数据** → 后续请求仍失败；Mitigation：保留既有「网络错误」提示，不在本变更做设置引导。
- **[Risk] probe 标记写早、请求未发出** → 不再重试；Mitigation：可接受，用户进入 UCG 推荐或登录会再次触发。
- **[Risk] 游客进 `/home` 后深链敏感路由** → Mitigation：子路由黑名单保持 redirect。
- **[Risk] 已登录关注空与网络错误空态混淆** → Mitigation：错误态仍用「加载失败」+ 重试，仅 `_error == null` 且空列表用发现空态。

## Migration Plan

1. 合并后国行 iOS 新装验证：冷启动进主页、probe 触发系统弹窗、游客浏览推荐、Dock gate 弹窗。
2. 已登录用户行为不变（除关注空态文案优化）。
3. 回滚：恢复 `cold_start_bootstrap` 与 `app_router` 两行 login redirect，移除 probe 调用。

## Open Questions

- 无（产品已确认：关注空态无按钮、消息/我的/发布弹窗拦截、游客进主页）。
