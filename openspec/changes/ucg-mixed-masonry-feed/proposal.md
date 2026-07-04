## Why

辩论 pivot（`ucg-debate-pivot`）将广场改为仅辩论单列 Feed、依赖 v2 接口 inline 评论预览，并移除 Dock 发帖与瀑布流，偏离 v2.0.3 已跑通的 moment 广场体验。产品现要求：**在 v2.0.3 瀑布流 + Dock 发帖骨架上叠加辩论能力**——混排 moment 与辩论帖、辩论帖全宽展示、投票后再拉评论；同时 **删除 App/小程序不再使用的 UCG v2 HTTP 路由**，在 v1 契约上扩展辩论字段与评论 `voteSide`，避免平行 API 维护成本。

本变更 **合并** `ucg-debate-feed-glass` 视觉（假玻璃 + 马卡龙 VS 条），并 **supersede** pivot 中与 Feed/Compose/Shell/评论契约/小程序列表相关的规格假设。

## What Changes

- **Feed 混排瀑布流**：推荐/关注恢复双列 Masonry；moment 帖 span=1；辩论帖（`debateLeft` 与 `debateRight` 均非空）span=2 全宽；辩论卡顺序：作者 → 文案 → 媒体（若有）→ `UcgDebateVsBar` → **投票后**才展示论点区。
- **帖子类型判定**：前端 **不得** 依赖 `type` 字段；`debateLeft.trim()` 与 `debateRight.trim()` 均非空 ⇒ 辩论帖。
- **Feed API**：App 改回 v1 `GET /ucg/app/api/feed/recommend|following`；**不得**在 Feed 响应附带评论预览；保留 `leftVoteCount`/`rightVoteCount`/`myVoteSide` enrichment。
- **评论 API**：App 与小程序改回 v1 `GET|POST /ucg/app/api/posts/{id}/comments`；v1 `UcgCommentItem` 增加 `voteSide`/`voteSideLabel`；**删除** go 侧 v2 Feed 与 v2 评论 HTTP 路由（实现可内复用 Redis 读模型）。
- **创建帖**：统一 v1 `POST /ucg/app/api/posts`；可选左右立场 + 多媒体；任一侧非空且另一侧为空 ⇒ **创建失败**并提示补全；两侧均非空 ⇒ 辩论帖（允许媒体）。
- **发帖入口**：恢复 Dock「+」直达 `UcgComposeScreen`（草稿优先）；**移除**广场辩论 FAB 与 `UcgDebateComposeScreen` 入口；Dock 短按 **不再** 弹出相册/拍摄入口 sheet（媒体在 compose 页内添加）。
- **懒评论**：Feed/详情辩论帖在未投票前 **不得** 请求或展示评论列表；投票成功后客户端拉 v1 评论并展示论点。
- **假玻璃视觉**：辩论全宽卡、VS 条、论点 pill、分享离屏布局沿用 `ucg-debate-feed-glass` 规范（无 `BackdropFilter`）。
- **小程序 `wx_ai_talk`**：**仅**保留分享落地详情页；移除列表页与 v2 API 调用；底部 CTA 引导下载 App 参与更多辩论。
- **BREAKING**：废弃 UCG v2 Feed/评论/创建帖 HTTP 路径；广场从 debate-only 单列恢复混排瀑布流；Dock 发帖流程变更（无入口 sheet）。

## Capabilities

### New Capabilities

- `ucg-feed-fake-glass`：Feed 假玻璃 panel/token（合并自 `ucg-debate-feed-glass`）。

### Modified Capabilities

- `ucg-square-feed`：恢复 Masonry 混排；辩论全宽卡 + 懒评论；假玻璃容器；Feed 走 v1 无评论预览。
- `ucg-compose-post`：Dock + 直达 compose；统一 v1 创建（文案+媒体+可选立场）；半填立场校验。
- `ucg-shell-navigation`：恢复 Dock 发帖；移除广场 FAB。
- `ucg-album-picker`：Dock 短按不再经入口 sheet（compose 内选媒体）。
- `ucg-post-comment`：v1 评论含 `voteSide`；辩论帖投票后才拉评论/展示论点。
- `ucg-debate-post`：前端 isDebate 由标签判定；辩论帖可有媒体；创建半填拒绝。
- `ucg-api-contract`：App 停用 v2 Feed/评论/创建；v1 评论 DTO 扩展。
- `ucg-debate-server-api`：go 删除 v2 路由；Feed 去评论预览；混排默认；v1 评论 voteSide；创建推断。
- `ucg-debate-miniprogram`：仅详情页引流；v1 API；无列表。
- `ucg-interactions`：moment 卡片进详情；辩论卡就地投票；debate 禁用点赞。
- `ucg-debate-vs-bar`：马卡龙 VS 条（合并 glass 视觉）。
- `ucg-debate-share`：分享布局与 Feed 假玻璃一致。

## Impact

- **flutter_ai_talk（本仓）**：`ucg_square_tab` Masonry；`ucg_repository` v1 路径；`ucg_models.isDebate`；`ucg_compose_screen` 立场字段；`ucg_shell` Dock+；删除 FAB/`UcgDebateComposeScreen` 引用；`UcgDebateFeedCard` 媒体+懒评论；假玻璃组件。
- **go_ai_talk（兄弟仓）**：`feed.go` 混排+去评论预览；`post.go` 创建推断；v1 `UcgCommentItem` 字段；删除 `api/v2/ucg_app_http.go` 路由注册；`ListComments` 填 voteSide（可内调 Redis）。
- **wx_ai_talk（兄弟仓）**：`app.json` 仅 detail；删 list 页；`utils/ucg.js` v1 路径；详情 CTA。
- **supersede**：`ucg-debate-pivot` 的 debate-only Feed、FAB compose、v2 Feed inline 评论、小程序列表；`ucg-debate-feed-glass` 并入本 change 后不再单独归档。
- **基线对照**：以 v2.0.3 的 `ucg-square-feed`、`ucg-compose-post`、`ucg-shell-navigation` 为恢复锚点，叠加辩论增量。
