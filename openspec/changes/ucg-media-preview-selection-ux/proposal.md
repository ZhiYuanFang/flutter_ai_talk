## Why

发布动态选视频后仅显示文件路径字符串、本地视频缩略图用 `Image.file` 无法渲染；相册 picker 整格点击即选中，无法先预览；历史编辑媒体条带缺少点击放大。三处共用同一套本地/相册预览能力，需统一交互与组件。

## What Changes

- **Compose 视频**：卡片式首帧预览（与图片九宫格视觉一致），去掉文件名行；点击全屏播放。
- **相册 picker**：点击缩略图中间全屏预览；仅右上角圆圈切换选中；未选中显示空心圆。
- **历史编辑媒体条带**：点击缩略图中间打开图片 lightbox 或视频全屏；本地视频用首帧缩略图。
- **共享 helper**：`showUcgLocalMediaPreview`、`showUcgAssetPreview`、`UcgLocalVideoThumb`（复用 `video_player` 首帧与现有全屏页）。

## Capabilities

### Modified Capabilities

- `ucg-compose-post`：视频本地预览与全屏
- `ucg-album-picker`：预览 vs 选中分区
- `history-event-media`：编辑条带 tap 预览

## Impact

| 区域 | 路径 |
|------|------|
| 预览与全屏 | `ucg_media_viewer.dart` |
| 本地视频缩略 | 新建或扩 `ucg_compose_local_preview.dart` |
| 发布页 | `ucg_compose_screen.dart` |
| 相册 | `ucg_album_picker_screen.dart` |
| 历史编辑 | `history_event_media_strip.dart` |

**go_ai_talk**：无变更。

## Out of Scope

- 自动夜空主题开关（见 `theme-schedule-opt-out-ui`，已完成）
- 绑定后 WS token 同步（见 `fix-history-ws-token-sync-after-bind`，已完成）
