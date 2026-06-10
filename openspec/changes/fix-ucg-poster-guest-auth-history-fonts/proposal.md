## Why

广场瀑布流视频帖仍使用 `_MasonryVideoCover` 静态占位，与已落地的 `ucg-server-image-thumbs-client-video-poster` 及朋友圈式 Feed 的客户端首帧封面方案不一致，影响浏览体验。与此同时，游客或本地残留过期 token 的用户在浏览公开 UCG 或主页时仍会触发鉴权失败 Toast「登录已过期，请重新登录」，与 `guest-home-entry-and-login-gates` 的匿名浏览设计相悖。主页历史时间轴虽已放大尾注数字，但越旧行字号衰减不足，时间层次仍偏弱。三项均为小范围体验修复，合并为一次变更以降低评审与发布成本。

## What Changes

- **UCG 瀑布流视频封面**：`UcgMasonryFeedCard` 在含视频帖时 MUST 复用 `UcgMomentsVideoTile` / `UcgInlineVideoPlayer` 的客户端首帧 poster 能力（poster-only 或等价参数），移除 `_MasonryVideoCover` 静态灰底占位；点击仍由外层卡片进详情，不在瀑布流内联播放。
- **游客/过期会话 Toast 抑制**：公开 UCG HTTP 接口（推荐 Feed、帖子详情、他人主页/帖子列表等）在游客浏览时 MUST 使用 `withAuthorization: false`；冷启动 `ensureFreshSession` 失败且用户处于「无有效登录态」时 MUST 静默 `signOut` 且不得弹出过期 Toast；喂养历史 WS 后台 refresh 失败时，若当前为游客或未登录 surface MUST 静默处理或抑制 Toast；真实已登录用户主动操作触发的 401/refresh 失败仍 MUST 提示重新登录。
- **历史行字号对比度**：`HomeHistoryTimelineTile` 降低最旧行字号下限（目标约 9–10 逻辑像素）并加强 `fromBottom` 衰减系数，使越旧记录 visibly 更小；`rowHeight` 保持约 40px，单行不溢出。

## Capabilities

### New Capabilities

- `guest-session-auth`：游客与残留过期 token 场景下的公开 API 无鉴权调用、冷启动静默清会话、后台 WS refresh 失败 Toast 抑制与真实登录过期 Toast 保留的边界。

### Modified Capabilities

- `ucg-square-feed`：瀑布流（masonry）布局的视频帖 MUST 展示客户端首帧封面，与朋友圈式 Feed tile 对齐。
- `home-history-timeline-row`：历史行随 `fromBottom` 的字号下限与衰减曲线加强，强化时间远近层次。

## Impact

- **Flutter**：`app/lib/ucg/ui/widgets/ucg_masonry_feed_card.dart`；`app/lib/ucg/data/ucg_repository.dart`（公开读接口 `withAuthorization`）；`app/lib/bootstrap/cold_start_bootstrap.dart`、`app/lib/providers/authorized_api_client_provider.dart` 或集中 session 清理 helper；`app/lib/data/remote_feed_repository.dart`（WS prepare token / Toast）；`app/lib/ui/home_history_timeline_tile.dart`。
- **后端（go_ai_talk）**：无变更；公开 UCG 读接口已支持无 Bearer。
- **规格关联**：对齐 `ucg-server-image-thumbs-client-video-poster` 视频 poster 意图；延续 `guest-home-entry-and-login-gates` 游客浏览；在 `home-history-timeline-typography` 行高与尾注强调基础上微调字号曲线。
- **测试**：Web `flutter run` 手工路径——游客进主页/广场、过期 token 冷启动、瀑布流视频封面、历史列表字号层次；已登录用户主动操作过期仍见 Toast。
