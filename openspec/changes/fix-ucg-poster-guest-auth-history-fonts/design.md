## Context

- **瀑布流视频封面**：`UcgMomentsVideoTile` / `UcgInlineVideoPlayer` 已在朋友圈式 Feed（`ucg_feed_moments_widgets.dart`）与聊天视频气泡落地客户端首帧 poster；`UcgMasonryFeedCard._MasonryVideoCover` 仍为灰底 + 播放图标静态占位，未接入同一套懒加载首帧逻辑。
- **游客 Toast**：`guest-home-entry-and-login-gates` 已允许游客进 `/home` 与 UCG 推荐浏览，但 `UcgRepository.fetchRecommendedFeed` 等公开读接口默认 `withAuthorization: true`；本地残留 access/refresh token 时 `ApiClient` 遇 401 会 refresh → 失败 → `onUnauthorizedFailed` → Toast。冷启动 `ColdStartBootstrap` 在 `ensureFreshSession` 失败时会 `signOut`，但 `authorizedApiClientProvider.onUnauthorizedFailed` 无条件 Toast。喂养历史 WS `_prepareAccessTokenForConnect` 在 refresh 失败时亦 Toast，即使用户当前以游客方式浏览。
- **历史字号**：`HomeHistoryTimelineTile` 当前 `fontSize = (13 - fromBottom * 0.25).clamp(11.0, 13.0)`，最旧行仅降至 11px，与 `home-history-timeline-typography` 已加强的尾注 2× 强调对比不足。

## Goals / Non-Goals

**Goals:**

- 瀑布流视频帖展示与 Feed tile 一致的客户端首帧 poster；瀑布流内不内联播放，点击进详情。
- 游客或冷启动清理后的无登录态：公开 UCG 读请求不带 Bearer；后台 session/WS 失败不弹「登录已过期」。
- 已登录用户主动触发的鉴权失败（如发评论、绑定宝宝）仍正常 Toast 引导重新登录。
- 历史行越旧字号 visibly 更小（下限约 9–10px），`rowHeight` 维持 40px。

**Non-Goals:**

- 修改 go_ai_talk 鉴权或新增 HTTP 路径。
- 为 `UcgInlineVideoPlayer` 增加全屏/内联播放新能力（仅 poster 模式复用）。
- 改变历史行 1.5× 事件名、2× 尾注数字等 `home-history-timeline-typography` 已落地规则。
- 修改登录页 UI 或微信/Apple 登录流程。

## Decisions

### 1. 瀑布流复用 `UcgInlineVideoPlayer` poster 能力

**Decision**：为 `UcgInlineVideoPlayer` 增加 `posterOnly`（或 `interactive: false`）参数：仅执行 `_loadPoster()`，不响应点击播放；瀑布流用固定 `aspectRatio: 3/4` 包裹。移除 `_MasonryVideoCover`。

**Why**：与 `ucg-server-image-thumbs-client-video-poster` 单点实现；共享 `_UcgVideoInitLimiter`。

**Alternatives**：在 masonry 内嵌 `UcgMomentsVideoTile` — 含内联播放与不同 aspect 逻辑，与「点击进详情」冲突。

### 2. 公开 UCG 读接口按登录态传 `withAuthorization`

**Decision**：在 `UcgRepository` 层，下列接口当 `!session.isLoggedIn` 时 `withAuthorization: false`：

- `fetchRecommendedFeed`
- `fetchPost`（帖子详情）
- `fetchUserPosts` / `fetchProfile`（他人主页，已有部分 `loggedIn` 分支可统一）

关注 Feed、我的帖子、写操作、通知等仍 `withAuthorization: true`。

**Why**：避免游客携带过期 Bearer 触发 401 链；与后端公开读能力一致。

**Alternatives**：全局 strip token when expired — 仍可能在 refresh 窗口竞态；不如读路径显式无鉴权。

### 3. 冷启动与 Toast 边界分离

**Decision**：

1. `SessionController.ensureFreshSession` 失败且 refresh 不可用或 refresh 失败时：仅 `signOut()`，**不** Toast（冷启动路径）。
2. `authorizedApiClientProvider.onUnauthorizedFailed`：若调用前 `session.isLoggedIn` 为 true（用户曾持有效 access），Toast；若已非登录态则静默（防重入）。
3. 可选集中 helper `signOutSilently()` vs `signOutWithExpiredToast()` 供 WS 与 API 层选用。
4. `remote_feed_repository._prepareAccessTokenForConnect`：若 `!session.isLoggedIn` 直接 return null 不 Toast；refresh 失败时仅当 `isLoggedIn` 且用户近期有喂养交互（或简单规则：`homeHistoryProvider` 已 mark initial load 且 logged in）才 Toast。

**Why**：区分「残留 token 清理」与「使用中 session 过期」。

**Alternatives**：全局 Toast debounce 5s — 掩盖真实过期；仅作补充手段用于同一帧多请求失败。

### 4. 历史字号曲线

**Decision**：`fontSize = (13 - fromBottom * 0.35).clamp(9.0, 13.0)`（实现时可微调系数）；`emphasis` 衰减可略加强 `(1.0 - fromBottom * 0.10).clamp(0.45, 1.0)`；尾注 RichText 内数字 2× 基于当前行 `fontSize` 计算，保持比例。

**Why**：在 40px 行高下单行仍可容纳 9–10px 正文 + 18px 级强调数字。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 瀑布流多视频同时 init 首帧 | 复用 `_UcgVideoInitLimiter`；仅视口内 tile 构建 player |
| 游客无 token 时部分 UCG 接口仍要求登录 | 仅对已确认公开的读路径设 `false`；写操作保持鉴权 |
| 静默 signOut 后用户不知曾过期 | 仅抑制冷启动/后台；主动操作仍 Toast |
| 9px 字号可读性 | 仅最旧若干行；Web 可验收 contrast |

## Migration Plan

1. 合并后 Web/Android 回归：游客广场、过期 token 冷启动、瀑布流视频帖、历史列表滚动。
2. 已登录用户：发评论/语音喂养触发过期仍见 Toast。
3. 回滚：恢复 masonry 占位与 repository 默认 `withAuthorization: true`。

## Open Questions

- 无（三项修复范围已在探索中确认）。
