## 1. 依赖与统一图片加载（`ucg-image-cache`）

- [x] 1.1 在 `app/pubspec.yaml` 添加 `cached_network_image` 依赖并 `flutter pub get`
- [x] 1.2 重构 `ucg_network_image.dart`：`UcgNetworkImage` 使用 `CachedNetworkImage` 替代裸 `Image.network`，保留 Web `webHtmlElementStrategy` 与 `errorBuilder` 行为
- [x] 1.3 当调用方传入 `width`/`height` 时，按 `MediaQuery.devicePixelRatio`（上限 3.0）设置 `memCacheWidth`/`memCacheHeight`
- [x] 1.4 `UcgAvatar` 经 `UcgNetworkImage` 自动获得磁盘缓存；确认列表头像调用点仍传明确尺寸

## 2. 视频封面数据模型（`ucg-media-cdn`）

- [x] 2.1 修改 `UcgPost.videoThumbnailUrl`：优先 `videoThumbCdnUrl`，回退 `UcgMediaUrl.thumbnailUrl(objectKey: videoKey, cdnUrl: videoCdnUrl, apiThumbnailUrl: videoThumbCdnUrl, apiThumbKey: videoThumbKey)`
- [x] 2.2 更新 `videoThumbnailUrl` 注释，移除「客户端首帧、不读服务端 thumb」表述

## 3. 瀑布流视频封面（`ucg-square-feed`）

- [x] 3.1 `UcgMasonryFeedCard` 视频帖：用 `UcgNetworkImage(url: post.videoThumbnailUrl)` + `UcgVideoPlayOverlayIcon` 替代 `UcgInlineVideoPlayer(posterOnly: true)`
- [x] 3.2 无 `videoThumbnailUrl` 时展示渐变占位 + 播放图标，不得初始化 `VideoPlayerController`
- [x] 3.3 瀑布流视频卡片点击仍导航详情，列表内不内联播放

## 4. 朋友圈视频封面（`ucg-square-feed` / `ucg-media-cdn`）

- [x] 4.1 `UcgMomentsVideoTile` 增加 `posterUrl` 参数；未播放时展示 `UcgNetworkImage` + 播放叠层，点击后再挂载/初始化 `UcgInlineVideoPlayer`
- [x] 4.2 `UcgMomentsMediaBlock` 传入 `post.videoThumbnailUrl` 与 `post.videoUrl`
- [x] 4.3 无 `posterUrl` 时降级为渐变占位 + 播放图标，点击再尝试 VideoPlayer 播放

## 5. VideoPlayer 组件收窄（可选清理）

- [x] 5.1 确认除详情/聊天/compose/全屏外，列表表面不再以 `posterOnly: true` 调用 `UcgInlineVideoPlayer`
- [x] 5.2 为 `UcgInlineVideoPlayer` 补充可选 `posterUrl`：若传入则跳过 `_loadPoster()` 网络视频初始化（供后续复用，本变更至少覆盖 masonry/moments）

## 6. 验证

- [x] 6.1 `flutter analyze`（`app/`）无新增 error
- [ ] 6.2 手工：广场瀑布流首屏含图帖与视频帖加载明显快于变更前；视频封面为静态图非黑屏等待
- [ ] 6.3 手工：杀进程重进广场，已浏览图片应快速展示（磁盘缓存命中）
- [ ] 6.4 手工：点击瀑布流/朋友圈视频仍可进入详情或内联播放；compose 与 lightbox 视频路径无回归
