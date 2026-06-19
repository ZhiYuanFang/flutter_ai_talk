## Why

原生 App 上 UCG 动态列表、详情与图片查看器加载明显偏慢。API 已分别返回 `thumbnailUrl` 与 `cdnUrl`，CDN 也已接入，但客户端仍使用裸 `Image.network`（无磁盘缓存、无按显示尺寸解码），且瀑布流视频封面通过 `VideoPlayerController` 拉取整段 mp4 提取首帧，导致首屏并发请求多、TTFB 与解码压力大。需在不大改服务端的前提下，先做 P0 客户端优化，显著改善列表与视频帖首屏体感。

## What Changes

- 为 `UcgNetworkImage` / `UcgAvatar` 引入磁盘+内存图片缓存（`cached_network_image`），统一 UCG 远程图加载路径。
- 列表/九宫格/瀑布流封面按控件逻辑尺寸传入 `memCacheWidth`/`memCacheHeight`（结合设备像素比），降低解码与内存占用。
- 瀑布流与动态列表中的**视频封面（仅 poster、未点击播放）**改为使用 API 返回的 `media[].thumbnailUrl`（OSS `video/snapshot`），**不得**为取首帧而 `initialize()` 网络视频。
- 点击播放、全屏播放、compose 本地预览等交互路径仍使用 `VideoPlayer`；大图 lightbox 仍使用 `cdnUrl` 全分辨率。
- **不在本变更范围**：详情页模糊背景改 thumb、lightbox precache、服务端预生成静态 thumb 文件、CDN 缓存策略调优（记为 P1/P2 follow-up）。

## Capabilities

### New Capabilities

- `ucg-image-cache`：UCG 远程图片磁盘缓存与统一加载组件行为（含 Web 策略保持）。

### Modified Capabilities

- `ucg-media-cdn`：列表/Feed 视频封面展示策略——由「客户端 VideoPlayer 首帧」改为「API `thumbnailUrl` 静态图」；与当前 `go_ai_talk` 已下发的视频 `thumbnailUrl` 对齐。
- `ucg-square-feed`（或等价瀑布流能力）：`UcgMasonryFeedCard` 视频区 MUST 使用 snapshot 图而非 VideoPlayer poster 初始化。

## Impact

- **Flutter**：`app/pubspec.yaml`（`cached_network_image`）、`ucg_network_image.dart`、瀑布流/九宫格/头像调用点、`ucg_models.dart`（暴露 `videoThumbnailUrl`）、`ucg_masonry_feed_card.dart`、`ucg_media_viewer.dart`（`posterOnly` 分支或替代组件）。
- **后端**：无协议变更；继续消费既有 `thumbnailUrl` / `cdnUrl` 字段。
- **基线**：引用并 delta 扩展 `v2.0.2` 中 `ucg-media-cdn`、瀑布流视频封面相关 Requirement（原「不得使用 OSS snapshot」与现实现及本变更意图冲突，以本 change delta 为准）。
