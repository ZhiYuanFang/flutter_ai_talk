## Approach

抽三层共享能力，三处 UI 只接入口：

1. **`UcgLocalVideoThumb`**：`VideoPlayerController.file` / `networkUrl` 初始化后 pause@0 显示首帧；网格内单条使用，配合 `_UcgVideoInitLimiter`。
2. **`showUcgVideoFullscreen`**：扩展现有 `_UcgVideoFullscreenPage`，支持 `videoUrl` 或 `filePath`（`VideoPlayerController.file`）。
3. **`showUcgAssetPreview(AssetEntity)`**：相册预览；图片用高分辨率 thumbnail 或 origin file → lightbox；视频用 asset.file → 全屏播放器。不改变 `UcgAlbumSelectionController` 状态。

## Compose 视频 UI

将 Row+文件名改为宽卡片（约 16:9，`AspectRatio` + 首帧 + 播放图标 + 右上角删除）。保留「更换视频须重新从入口选」提示。远程视频仍用 `UcgNetworkImage`（CDN 封面）。

## Album Picker 手势

```
Stack
├── thumbnail (GestureDetector → preview)
├── Positioned topRight: 44dp 热区 → toggle
└── video duration badge
```

未选中：空心白边圆；选中：primary 实心圆 + 序号（视频无序号，与现有一致）。

## History Strip

在 `LongPressDraggable` 内层包 `GestureDetector(onTap: preview)`；删除按钮保持独立。远程/本地分流到 lightbox 或 video fullscreen。

## Web

本地 file 视频：缩略降级为 icon+播放钮；全屏尝试 `VideoPlayerController.networkUrl(blob:)` 若 path 为 blob。
