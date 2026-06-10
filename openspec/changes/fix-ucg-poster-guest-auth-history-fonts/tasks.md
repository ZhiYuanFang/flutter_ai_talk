## 1. 瀑布流视频首帧封面（ucg-square-feed）

- [x] 1.1 `UcgInlineVideoPlayer` 增加 `posterOnly`（或 `interactive: false`）：仅 `_loadPoster()`、禁用点击播放（design §1）
- [x] 1.2 `UcgMasonryFeedCard._MasonryMedia`：视频分支改用 `UcgInlineVideoPlayer`（`aspectRatio: 3/4`、`posterOnly: true`），删除 `_MasonryVideoCover`
- [x] 1.3 确认瀑布流点击仍由外层 `UcgSurfaceCard.onTap` 进详情，卡片内无内联有声播放
- [x] 1.4 Web 手工验收：推荐瀑布流含视频帖展示首帧；滚出视口无 controller 泄漏；失败回退渐变+播放图标

## 2. 游客/过期会话 Toast 抑制（guest-session-auth）

- [x] 2.1 `UcgRepository`：游客时 `fetchRecommendedFeed`、`fetchPost`、`fetchUserPosts`、`fetchProfile`（他人）传 `withAuthorization: false`（spec「公开 UCG 读接口」）
- [x] 2.2 确认关注 Feed、我的帖子、写操作、通知等仍默认 `withAuthorization: true`
- [x] 2.3 冷启动：`ensureFreshSession` 失败路径仅 `signOut`，不 Toast；必要时在 `SessionController` 或 bootstrap 层区分静默清理（spec「冷启动静默清理」）
- [x] 2.4 `authorizedApiClientProvider.onUnauthorizedFailed`：仅当失败前 `isLoggedIn` 为 true 时 Toast；已非登录态静默（design §3）
- [x] 2.5 `remote_feed_repository._prepareAccessTokenForConnect`：`!isLoggedIn` 直接 return null 不 Toast；refresh 失败 Toast 仅限已登录且非游客后台路径（spec「后台 WS 抑制」）
- [x] 2.6 手工验收：本地植入过期 token → 冷启动无 Toast 进主页；游客逛广场无 Toast；已登录发评论/喂养操作过期仍 Toast

## 3. 历史行字号衰减（home-history-timeline-row）

- [x] 3.1 `HomeHistoryTimelineTile`：调整 `fontSize` 公式（如 `(13 - fromBottom * 0.35).clamp(9.0, 13.0)`）并可选加强 `emphasis` 衰减（design §4）
- [x] 3.2 确认 `rowHeight` 仍为 40、`slotHeightFor` 不变；尾注 RichText 2× 数字仍基于行内 `fontSize`
- [x] 3.3 手工验收：滚动历史列表，最旧行 visibly 小于最新行且单行不溢出

## 4. 回归

- [x] 4.1 `flutter analyze`（`app` 包）无新增 error
- [x] 4.2 Web `flutter run` 交叉路径：游客主页+广场、瀑布流视频、历史字号、已登录过期 Toast
