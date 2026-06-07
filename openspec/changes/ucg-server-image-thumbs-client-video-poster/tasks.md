## 1. 后端 CDN helper（go_ai_talk）

- [x] 1.1 在 `d:\work\go_ai_talk\internal\services\ucg\` 新增 `BuildCdnURL` 与 `BuildImageThumbnailURL`，OSS 处理串固定为 `image/auto-orient,1/resize,m_lfit,w_200/quality,q_90/format,jpg`（`ucg-api-contract` / design §1）
- [x] 1.2 **不得**实现 `BuildVideoPosterURL` 或任何 video snapshot 辅助函数（design Non-Goals）

## 2. 后端 DTO 填充（go_ai_talk）

- [x] 2.1 Feed post `media[]`：`mediaKind=image` 时填充 `thumbnailUrl`；video 仅 `cdnUrl`（`ucg-api-contract`）
- [x] 2.2 `GET /profile/me` 与 `GET /profile/{wxId}`：有 `avatarKey` 时填充 `avatarThumbnailUrl`（`ucg-profile`）
- [x] 2.3 点赞列表 / follow 列表 / 帖子作者 enrichment：头像透出 `avatarThumbnailUrl`（与 profile enrichment 一致）
- [x] 2.4 聊天 `GET /conversations/{id}/messages`：图片消息填充 `mediaCdnUrl` + `mediaThumbnailUrl`；确认 HTTP handler 不剥离 media 字段（`ucg-chat-ui`）
- [x] 2.5 `GET /conversations`：会话项 enrichment 增加 `peerAvatarThumbnailUrl`（或 canonical 命名与 Flutter 对齐）（`ucg-chat-ui`）

## 3. Flutter 模型与 URL 解析

- [x] 3.1 `d:\work\flutter_ai_talk\app\lib\ucg\data\ucg_models.dart`：解析 `thumbnailUrl`、`avatarThumbnailUrl`、`mediaThumbnailUrl` 及别名（`ucg-api-contract`）
- [x] 3.2 `d:\work\flutter_ai_talk\app\lib\ucg\data\ucg_media_url.dart`：`thumbnailUrl()` 仅用 API 字段，缺失回退 `fullUrl`；删除或废弃 `ossProcessUrl` 及 `defaultThumbWidth` OSS 逻辑（supersede `unify-ucg-wxid-api-alignment` §40.1）
- [x] 3.3 `UcgPost.imageThumbnailUrls` / `videoThumbnailUrl`：图片走 API thumb；视频 **不** 读服务端 thumb（`ucg-square-feed`）

## 4. Flutter UI — 图片缩略图

- [x] 4.1 Feed 九宫格 / 我的动态时间轴 / 帖子详情：`UcgMomentsMediaGrid`、`ucg_my_post_timeline_item.dart` 使用 API `thumbnailUrl`（`ucg-square-feed`）
- [x] 4.2 **Profile 主页/头部**（`ucg_profile_header.dart`）：使用全分辨率 `avatarUrl`（`ucg-profile`）
- [x] 4.3 **所有其他 `UcgAvatar` 调用点**（Feed 作者头像、点赞网格、关注列表、消息 Tab、会话列表、聊天 AppBar、聊天气泡发送者头像等）：**必须**使用 `avatarThumbnailUrl`（或 `peerAvatarThumbnailUrl`），不得加载全分辨率 `avatarUrl`（`ucg-profile` / `ucg-square-feed` / `ucg-chat-ui`）
- [x] 4.4 聊天图片气泡：使用 `mediaThumbnailUrl` 预览，点开用 `mediaCdnUrl`（`ucg-chat-ui` / `ucg_chat_screen.dart`）
- [x] 4.5 Lightbox / 全屏图片：继续 `UcgMediaUrl.fullUrl` / `cdnUrl`，不得改用 thumb（`ucg-square-feed`）

## 5. Flutter UI — 视频客户端首帧封面

- [x] 5.1 `ucg_feed_moments_widgets.dart` / `UcgInlineVideoPlayer`：未播放前客户端懒加载首帧（`VideoPlayerController` init → mute → t=0 pause；滚出 dispose）；移除 OSS `video/snapshot` 与 API video `thumbnailUrl` 依赖（`ucg-square-feed`）
- [x] 5.2 保留/复用 `_UcgVideoInitLimiter` 控制列表并发 init（design §4）
- [x] 5.3 首帧失败回退渐变+播放图标；点击后仍用完整 `videoUrl`/`cdnUrl` 播放（`ucg-square-feed`）
- [x] 5.4 **聊天视频气泡**（`ucg_chat_screen.dart`）：**必须**展示客户端首帧 poster，与 Feed tile 同方案；不依赖服务端 `mediaThumbnailUrl`（`ucg-chat-ui`）

## 6. 部署顺序（强制）

- [ ] 6.1 **先**部署 `go_ai_talk` ucg-service（含 CDN helper 与 DTO thumb 字段）至目标环境，并验证 Feed/profile/chat API 响应含 `thumbnailUrl` / `avatarThumbnailUrl` / `mediaThumbnailUrl`
- [ ] 6.2 **后**发布 Flutter 版本：消费上述 thumb 字段、移除 `ossProcessUrl` fallback、落地头像路由与聊天视频首帧 poster
- [ ] 6.3 **禁止**在未完成 6.1 时发布 6.2 的 Flutter 构建

## 7. 手工验证

- [ ] 7.1 Feed 多图帖：列表为 w_200 缩略图，lightbox 为全分辨率（Charles/日志核对 URL 无客户端 `x-oss-process`）
- [ ] 7.2 Feed 视频帖：未点击见首帧封面，点击内联播放；响应 JSON 中 video media 无 `thumbnailUrl`（**2025-06-08 修复：** 广场双列 `UcgMasonryFeedCard` 已改用 `UcgMomentsVideoTile` / `UcgInlineVideoPlayer`，与「我的动态」一致；需手工验证广场列表首帧封面）
- [ ] 7.3 **聊天视频气泡**：未点击见首帧封面，点击播放完整 `mediaCdnUrl`
- [ ] 7.4 Profile 主页/头部：展示全分辨率 `avatarUrl`；Feed 作者、点赞网格、消息列表、聊天气泡等列表 surface 展示 `avatarThumbnailUrl`
- [ ] 7.5 聊天图片气泡：使用 `mediaThumbnailUrl` 预览
- [ ] 7.6 Web 冒烟：图片 CORS-safe；视频首帧失败时有占位

## 8. 规格与追溯

- [ ] 8.1 实现 PR 说明引用本变更：`ucg-server-image-thumbs-client-video-poster` 及对应 Requirement 标题
- [x] 8.2 确认 supersede `unify-ucg-wxid-api-alignment` §40 客户端 OSS 与旧 video snapshot spec 场景（本变更 specs delta 已 MODIFIED）
