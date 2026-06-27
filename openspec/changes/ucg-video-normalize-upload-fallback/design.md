## Context

- 失败样例：`KbRbUC1ixKvk0BdPqvoR6hY7ZlmX7U7y.mp4` — H.264 High、1792×1024、37fps、**moov 在文件尾**；4.4MB 因 `<20MB` 被 `ucgPrepareVideoBytes` 原样上传。
- 当前上传：`ucgUploadBytes(isVideo:true)` **不处理** video bytes；`ucgPrepareVideoBytes` 在 5 处手动调用，易与业务渠道耦合。
- 已有 Android 本地预览失败时 `openSystemPlayer(filePath/contentUri)`，**不支持 https CDN URL**。
- 基线 `ucg-media-dedup`：`transform_version` 首版 `v1`；normalize 算法变更须 bump。

## Goals / Non-Goals

**Goals:**

- 单一 API **`ucgUploadLocalVideo(repo, sourcePath, …)`** 作为本地视频 OSS 上传唯一门闸。
- 原生：ffmpeg 输出统一 **MP4 · H.264 Main · AAC（无源则静音轨）· faststart · ≤15s · 目标 ≤20MB**。
- Web：validate + v1 直传；规格声明服务端转码义务（参数与 v2 一致）。
- 内联播放失败：Feed/详情/全屏/聊天展示 **外链播放** 按钮。
- `kUcgMediaTransformVersion` 对 native normalized 视频使用 **`v2`**。

**Non-Goals（本 change Flutter 实现范围外）:**

- go_ai_talk 服务端 ffmpeg worker 实现（仅 spec backlog + design 记录）。
- 存量 OSS v1 对象批量重转码。
- Web 端 MediaRecorder 新增录像入口（未来若做，仍走 `ucgUploadLocalVideo`）。
- ffmpeg.wasm。
- 修改 UCG API 契约（仍 resolve/register + contentHash）。

## Decisions

### 1. 统一入口 `ucgUploadLocalVideo`

**选择**：新建 `ucgUploadLocalVideo`；内部 `validate → normalize → ucgUploadBytes(..., transformVersion)`。

**理由**：业务渠道（compose、聊天、历史同步、相册直传）只关心「上传本地视频」，不应各自 prepare。

**备选**：继续 spread `ucgPrepareVideoBytes` — 已证明易漏、难维护，否决。

### 2. 原生 normalize：ffmpeg_kit

**选择**：`ffmpeg_kit_flutter_new_min_gpl`（GPL min 变体，含 libx264；APK 约增数 MB/ABI，见 README）。

**命令模板**（有音轨 / 无音轨两模板，见 tasks）：

- `-c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p`
- `-vf "scale='min(1280,iw)':-2" -r 30 -t 15`
- 无音轨：`-f lavfi -i anullsrc=...` + `-map 0:v:0 -map 1:a:0 -shortest`
- `-c:a aac -b:a 128k -ar 44100 -ac 2`
- `-movflags +faststart`

**理由**：`video_compress` 不可控 profile/faststart；与播放侧本地转码（`ucg_video_playback.dart`）职责分离。

### 3. 每条本地视频必转

**选择**：去掉 `bytes.length <= videoMaxBytes` 早退；一律 ffmpeg。

**理由**：小文件仍可能是 High/moov-at-end；15s 内转码成本可接受。

### 4. Web：服务端补，不用 wasm

**选择**：Web 分支 validate 后读 bytes 上传，`transform_version=v1`；design 附服务端 worker 参数对齐 v2。

**理由**：用户明确拒绝 ffmpeg.wasm；MediaRecorder 仅适合作采集，不适合作相册文件 normalize。

### 5. transform_version

| 路径 | version |
|------|---------|
| Native ffmpeg 输出 | `v2` |
| Web raw 直传 | `v1`（服务端转完后 blob 登记为 v2 对象 — Phase 2） |
| 图片 | 仍 `v1` |

常量：`kUcgMediaTransformVersionVideoNative = 'v2'`；Web 视频 upload 显式传 `v1`。

### 6. 播放兜底

**选择**：

- 扩展 `ucgOpenSystemVideoPlayer` 或新增 `ucgOpenExternalVideoPlayer(videoUrl, filePath, contentUri)`。
- Android：https `Intent.ACTION_VIEW` + `video/*`。
- iOS/Web：`url_launcher` `LaunchMode.externalApplication`。
- 挂接：`UcgInlineVideoPlayer`、`_UcgVideoFullscreenPage` 失败 UI；保留「重试」。

**理由**：覆盖存量 v1 CDN；与 upload normalize 互补。

### 7. compose 槽位状态

**选择**：`UcgComposeMediaSlotStatus` 增加 `preparing`（或 uploading 前子阶段），文案「正在处理视频…」。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| ffmpeg_kit 增包体 | min 变体；仅 mobile 依赖 |
| 转码 5–30s 阻塞感 | preparing UI；slot 后台任务已有模式 |
| Web 上传后 App 内仍不可播至服务端完成 | thumbnail 可用；规格 Phase 2 worker；兜底外链 |
| v1/v2 dedup 并存 | 不同 transform_version 天然隔离 hash 空间 |
| 服务端 worker 未就绪 | proposal 分 Phase；Web 用户量相对小 |

## Migration Plan

1. 实现 `ucgUploadLocalVideo` + ffmpeg；单元/手工验证一条 High/moov-at-end 样例。
2. 替换所有 video upload 调用点；删除对外 `ucgPrepareVideoBytes` 导出（或标记 `@visibleForTesting` 内部）。
3. 播放兜底 UI + Android videoUrl。
4. bump transform v2；README 注明 Web 服务端 backlog。
5. 回滚：feature flag 或 revert；已 v2 上传对象无需回滚 OSS。

## Open Questions

- ffmpeg_kit 具体变体（GPL vs https）需法务/许可证确认 — 实现 tasks 首项 spike。
- 服务端 worker 触发机制（OSS 事件 vs register 后队列）由 go 仓库单独立项。

## Phase 2 backlog（go_ai_talk，本仓库不实现）

Web 端 `transform_version=v1` 视频上传完成后，go_ai_talk 服务端 MUST 异步 ffmpeg 转码为与 native v2 相同 canonical 格式：

- MP4 · H.264 **Main** · yuv420p · max 1280px 宽 · 30fps · ≤15s
- 无音轨补静音 AAC stereo · `-movflags +faststart` · 目标 ≤20MB
- 转码完成后登记为 v2 对象（或替换 blob 并 bump hash 空间）

触发机制（OSS 事件 vs register 后队列）由 go 仓库单独立项；Flutter 端在 worker 未就绪前依赖封面展示 + `ucg-video-playback-fallback` 外链播放。
