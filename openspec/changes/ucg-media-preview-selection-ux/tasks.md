## 1. 共享预览能力

- [x] 1.1 `ucg_media_viewer.dart`：`showUcgVideoFullscreen` 支持 network URL 与本地 filePath；导出 `showUcgLocalImageLightbox`（单图 file/memory/url）
- [x] 1.2 新建 `UcgLocalVideoThumb`：file/network 首帧缩略，限并发 init
- [x] 1.3 `showUcgAssetPreview(context, AssetEntity)`：相册全屏预览（图片/视频）

## 2. Compose 视频 UI

- [x] 2.1 `ucg_compose_screen.dart`：视频区改为卡片预览，去掉 `_videoLabel` 路径文案
- [x] 2.2 点击视频卡片打开全屏播放（本地 file / 远程 CDN URL）

## 3. 相册 picker 交互

- [x] 3.1 `_AssetCell`：中区 tap → preview；右上圈 tap → toggle；未选中空心圆

## 4. 历史编辑条带

- [x] 4.1 `history_event_media_strip.dart`：tap 预览；本地视频缩略改用 `UcgLocalVideoThumb`

## 5. 验证

- [x] 5.1 `flutter analyze` 无新增 error
