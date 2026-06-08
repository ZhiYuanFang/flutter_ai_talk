# Design: 广场 Feed 媒体点击进详情

## 现状

`UcgMasonryFeedCard` 外层 `UcgSurfaceCard.onTap` 已绑定进详情，但 `_MasonryMedia` 内图片包了独立 `GestureDetector` 调 `showUcgPhotoLightbox`；视频用 `UcgMomentsVideoTile` → `UcgInlineVideoPlayer` 内联播放，拦截卡片点击。

## 方案

```
点击目标          改前              改后
────────────────────────────────────────────
图片/×N 角标    lightbox          card onTap → 详情
视频封面        内联播放          静态封面 → 详情
头像            个人主页          不变
文字/空白       详情              不变
详情页内媒体    lightbox/播放     不变
```

### 图片

移除 `_MasonryMedia` 中图片 `GestureDetector`，点击由 `UcgSurfaceCard.onTap` 统一处理。

### 视频

新增 `_MasonryVideoCover`（或 `UcgMomentsVideoTile` 的 `posterOnly` 模式）：

- `AspectRatio` 与 masonry 图片一致（3/4）
- 深色占位 + 居中播放图标（不 init `VideoPlayerController`）
- 不包独立 `onTap`，依赖 card `onTap`

首帧 poster 可在后续 change 接入；本变更优先行为正确与列表性能。

## 规格

MODIFY `ucg-square-feed`：广场 Feed 媒体 tap → 详情；lightbox 仅限详情页及其他 surface（聊天等）。
