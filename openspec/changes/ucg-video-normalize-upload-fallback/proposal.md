## Why

部分 CDN 视频（如 AI 生成 mp4：H.264 High、moov 在文件尾）在 App 内 `VideoPlayer` 初始化失败；同时当前 `ucgPrepareVideoBytes` 在 **≤20MB 时原样上传**，未做 normalize，且 prepare 逻辑散落在 compose、聊天、历史同步等多处，易漏调。需在 **统一本地视频上传入口** 强制转码为可播格式，并在内联播放仍失败时提供 **系统/外链播放器兜底**。

## What Changes

- 新增 **`ucgUploadLocalVideo`**：所有「本地视频 path → OSS」必须经此入口；内部 validate → normalize → hash → upload。
- **原生（iOS/Android）**：每条本地视频 **必转**（ffmpeg_kit）：H.264 **Main**、无音轨补 **静音 AAC**、`-movflags +faststart`；`transform_version` 升为 **`v2`**。
- **Web**：客户端 **不** 使用 ffmpeg.wasm；validate 后直传 raw（`transform_version` **`v1`**），canonical mp4 由 **服务端 ffmpeg** 异步补齐（本仓库 Flutter change 仅文档化契约与 backlog，实现落在 go_ai_talk）。
- 迁移现有 `ucgPrepareVideoBytes` 调用点至 `ucgUploadLocalVideo`；`ucgUploadBytes(isVideo:true)` 不得被业务直接用于未 normalize 的 bytes。
- **播放兜底**：CDN 视频 `VideoPlayer` 初始化/播放失败时，UI 提供 **「用系统播放器打开」**（Android `ACTION_VIEW` https；iOS `url_launcher`）；compose 本地预览失败路径扩展支持 `videoUrl`。
- compose 上传槽位增加 **「正在处理视频…」** 状态（preparing），与 uploading 区分。

## Capabilities

### New Capabilities

- `ucg-video-upload-normalize`：统一本地视频上传门闸、validate、原生 ffmpeg normalize、Web 直传与服务端转码契约。
- `ucg-video-playback-fallback`：网络/内联视频播放失败时的外链系统播放器兜底与 UI。

### Modified Capabilities

- `ucg-media-dedup`：视频 normalize 后使用 `transform_version` **`v2`**；Web 直传仍为 **`v1`** 直至服务端转码完成。
- `ucg-compose-post`：compose 槽位上传视频 MUST 经统一上传入口；上传前 preparing 状态。
- `ucg-chat-ui`：聊天发送本地视频 MUST 经统一上传入口。
- `history-event-square-sync`：同步广场时本地视频上传 MUST 经统一上传入口。

## Impact

- **Flutter**：`ucg_media_picker.dart`、`ucg_media_compress.dart`（或新 `ucg_video_upload.dart`）、`ucg_compose_media_slot.dart`、`ucg_album_picker.dart`、`history_event_square_sync.dart`、`ucg_android_local_video.dart`、`MainActivity.kt`、`ucg_media_viewer.dart`；`pubspec.yaml` 增加 `ffmpeg_kit_flutter`（min 变体）。
- **依赖**：APK/IPA 体积增加；15s 视频转码增加发帖/发消息耗时。
- **服务端（Phase 2，go_ai_talk）**：Web 上传 v1 视频的异步 ffmpeg worker；与客户端 v2 输出参数一致。
- **存量**：已发布 v1 视频仍可能内联失败，依赖播放兜底；新帖 native 路径显著改善。
