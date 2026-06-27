## 1. 依赖与 spike（`ucg-video-upload-normalize`）

- [x] 1.1 评估并添加 `ffmpeg_kit_flutter` 变体到 `pubspec.yaml`（记录 APK 体积影响）
- [x] 1.2 spike：对样例 High/moov-at-end mp4 跑 normalize 命令，确认 Main+AAC+faststart 输出可内联播放

## 2. 统一上传门闸（`ucg-video-upload-normalize`）

- [x] 2.1 新增 `ucg_video_upload.dart`（或扩展 `ucg_media_compress.dart`）：`ucgValidateVideoSource`、`ucgNormalizeVideoNative`（ffmpeg）、`ucgUploadLocalVideo`
- [x] 2.2 实现无音轨 anullsrc 与有音轨两路 ffmpeg 命令；超 20MB 降参重试
- [x] 2.3 Web 分支：validate + raw bytes + `transform_version=v1`；禁止 wasm
- [x] 2.4 `ucgUploadBytes` 增加可选 `transformVersion`；视频业务改走 `ucgUploadLocalVideo`
- [x] 2.5 将 `kUcgMediaTransformVersion` 拆为图片 v1 / 原生视频 v2 常量

## 3. 迁移调用点（`ucg-video-upload-normalize`）

- [x] 3.1 `ucg_compose_media_slot.dart` → `ucgUploadLocalVideo`；槽位 `preparing` 状态 + UI 文案
- [x] 3.2 `ucg_media_picker.dart`（`ucgUploadChatLocalMedia`、`ucgPickAndUploadVideo`）→ 统一入口
- [x] 3.3 `ucg_album_picker.dart` 视频直传 → 统一入口
- [x] 3.4 `history_event_square_sync.dart` → 统一入口
- [x] 3.5 移除或内联 `ucgPrepareVideoBytes` 对外导出；grep 确认无遗漏

## 4. 播放兜底（`ucg-video-playback-fallback`）

- [x] 4.1 新增 `ucgOpenExternalVideoPlayer(videoUrl, filePath, contentUri)`；Android `MainActivity` 支持 https `videoUrl`
- [x] 4.2 `UcgInlineVideoPlayer` 失败 UI：「用系统播放器打开」+ 保留重试
- [x] 4.3 `_UcgVideoFullscreenPage` 失败 UI：network `videoUrl` 也显示外链按钮
- [x] 4.4 iOS：`url_launcher` externalApplication 兜底

## 5. 验证与文档

- [x] 5.1 原生：选/发 15s 内视频 → logcat 确认 v2 上传；内联播放成功
- [x] 5.2 原生：对已知失败 CDN mp4（存量 v1）→ 内联失败时可外链打开
- [x] 5.3 Web：发帖视频 v1 直传仍成功（不要求客户端 ffmpeg）
- [x] 5.4 `app/README.md` 补充视频 normalize 与 Web 服务端 backlog 说明
- [x] 5.5 design 记录 go_ai_talk Phase 2 server transcode backlog（本仓库不实现）
