## Context

- 原生 App 上 UCG 图片加载慢；API 已返回 `thumbnailUrl` + `cdnUrl`，列表路径已选用 thumb，但 `UcgNetworkImage` 仍为裸 `Image.network`。
- 瀑布流视频帖使用 `UcgInlineVideoPlayer(posterOnly: true)`，在 `initState` 中 `VideoPlayerController.networkUrl` + `initialize()`，等价于为封面拉取视频流，与图片帖竞争带宽与解码资源。
- 基线 `v2.0.2` 曾要求瀑布流「客户端首帧、不得 OSS snapshot」，与当前 `go_ai_talk` 实现（`post.go` 对视频下发 `BuildVideoSnapshotURL`）及性能目标冲突；本变更以 **列表用 snapshot、点击后 VideoPlayer 播放** 为准，修订 delta spec。

## Goals / Non-Goals

**Goals:**

- P0：UCG 远程图统一走带**磁盘缓存**的加载组件，二次进入/滚动回退显著加速。
- P0：列表/Feed 表面（瀑布流、九宫格、头像）按**显示尺寸**解码（`memCacheWidth`/`memCacheHeight`）。
- P0：瀑布流/朋友圈列表**视频封面（未播放）**使用 API `thumbnailUrl`（OSS snapshot 图），禁止为 poster 初始化 `VideoPlayer`。
- 保持 Web `WebHtmlElementStrategy.prefer` 行为不变。

**Non-Goals（P1/P2，本变更不做）:**

- 详情页模糊背景改 thumb、lightbox `precacheImage`。
- 服务端上传时预生成独立 thumb 对象、CDN 缓存策略调优。
- 修改 OSS `w_200` 处理参数。
- 改变点击播放、全屏、compose 本地视频预览的 VideoPlayer 路径。

## Decisions

### 1. 依赖 `cached_network_image`

- **选择**：在 `UcgNetworkImage` / `UcgAvatar` 内用 `CachedNetworkImage`，保留现有对外 API（`url`, `width`, `height`, `fit`, `errorBuilder`）。
- **理由**：成熟、磁盘+内存双层缓存；比自研 `flutter_cache_manager` 包装更省事。
- **备选**：仅用 `Image.network` + 调大 `PaintingBinding.imageCache` → 无磁盘，冷启动仍慢，否决。

### 2. 解码尺寸：`memCacheWidth` / `memCacheHeight`

- **选择**：当调用方传入 `width`/`height` 时，乘以 `MediaQuery.devicePixelRatio`（上限如 3.0）写入 `memCacheWidth`/`memCacheHeight`；未传尺寸时不强制（lightbox 全图）。
- **理由**：列表格子已知尺寸；减少内存与解码时间。
- **备选**：全局固定 400px → 对头像/大图不适用，否决。

### 3. 视频 Feed 封面：API snapshot 图 + 播放按钮叠层

- **选择**：`UcgMasonryFeedCard` / `UcgMomentsVideoTile` 在 **仅展示封面** 时用 `UcgNetworkImage(url: post.videoThumbnailUrl)` + `UcgVideoPlayOverlayIcon`；点击仍导航详情或进入 `UcgInlineVideoPlayer` 播放态。
- **模型**：`UcgPost.videoThumbnailUrl` 改为解析 `videoThumbCdnUrl`（已有字段），回退 `UcgMediaUrl.thumbnailUrl(...)`。
- **理由**：与 `go_ai_talk` 已下发字段一致；避免列表拉 mp4。
- **备选**：保留 VideoPlayer 首帧 → 性能差，否决。
- **修订基线**：MODIFIED `ucg-square-feed` 与 `ucg-media-cdn` 中「视频不得 thumbnailUrl / 不得 snapshot」条款。

### 4. `UcgInlineVideoPlayer.posterOnly` 使用范围收窄

- **选择**：`posterOnly: true` 的调用方改为 snapshot 图组件；`UcgInlineVideoPlayer` 保留给**需要内联播放/可点击播放**的场景（详情、朋友圈可播 tile）。
- **理由**：避免一处改逻辑、多处受益。

### 5. Web 兼容

- **选择**：Web 仍可用 `CachedNetworkImage`；CORS 问题沿用现有 CDN/`UcgNetworkImage` 策略；若个别环境 CORS 失败，`errorBuilder` 占位不变。
- **理由**：用户主诉原生；Web 不回归即可。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| OSS snapshot 封面与真实首帧不一致 | 可接受；列表性能优先；播放仍以视频为准 |
| snapshot URL 首次 TTFB 慢 | 磁盘缓存缓解二次；P2 再考虑预生成 |
| `cached_network_image` 包体积增加 | 单依赖，收益大于成本 |
| 基线「客户端首帧」被替换 | delta spec 明确 MODIFIED；与后端现状对齐 |
| 旧帖无 `thumbnailUrl` | 回退渐变占位+播放图标，不初始化 VideoPlayer |

## Migration Plan

1. 添加依赖，改 `UcgNetworkImage`（透明切换，调用方无感）。
2. 改 `UcgPost.videoThumbnailUrl` 与瀑布流/朋友圈视频封面组件。
3. 手工验证：广场首屏、含视频 feed、杀进程重进（磁盘缓存）、详情内联播放仍正常。

回滚：还原 `ucg_network_image.dart` 与 masonry 视频组件即可。

## Open Questions

- 朋友圈 `UcgMomentsVideoTile` 是否在本变更一并改 snapshot，还是仅瀑布流？**默认：一并改**（同一性能问题）。
- 磁盘缓存上限是否需自定义 `CacheManager`？**默认：先用库默认配置**。
