## ADDED Requirements

### Requirement: Client SHALL upload local video only through ucgUploadLocalVideo

The Flutter client MUST route every local video file upload to OSS (compose slot, chat attachment, history square sync, album immediate upload, and equivalent paths) through a single API `ucgUploadLocalVideo`. The API MUST validate source media, normalize bytes on native mobile, compute content hash on final prepared bytes, and invoke resolve/register upload. Business code MUST NOT call `ucgPrepareVideoBytes` followed by `ucgUploadBytes(isVideo: true)` directly. Remote-only slots (`objectKey` already on OSS) MUST NOT re-normalize or re-upload.

Flutter 客户端 MUST 将所有本地视频 OSS 上传统一至 `ucgUploadLocalVideo`；该 API 负责校验、原生 normalize、哈希与 resolve/register 上传。业务代码 MUST NOT 直接组合 `ucgPrepareVideoBytes` + `ucgUploadBytes(isVideo:true)`。已是远程 `objectKey` 的槽位 MUST NOT 再次转码或上传。

#### Scenario: Compose slot background upload uses unified gate

- **WHEN** compose 视频槽 `needsUpload` 且 `localPath` 非空
- **THEN** Client SHALL 调用 `ucgUploadLocalVideo` 而非分散 prepare
- **AND** 成功后槽位 `objectKey` SHALL 指向 normalized 上传结果

#### Scenario: Chat local video upload uses unified gate

- **WHEN** 用户发送聊天本地视频附件
- **THEN** Client SHALL 经 `ucgUploadLocalVideo` 上传
- **AND** MUST NOT 绕过 normalize 直接 `ucgUploadBytes`

#### Scenario: Remote video slot skips normalize

- **WHEN** compose 编辑帖仅含远程 `objectKey` 无 `localPath`
- **THEN** Client SHALL NOT 调用 `ucgUploadLocalVideo`

### Requirement: Native mobile SHALL ffmpeg-normalize every local video before upload

On iOS and Android, `ucgUploadLocalVideo` MUST transcode every local video before upload (no size-based skip). Output MUST be MP4 with H.264 **Main** profile (`-profile:v main`), yuv420p, max duration 15 seconds, target max dimension 1280px width (preserve aspect), 30 fps, `-movflags +faststart`. If source has no audio track, output MUST include a silent AAC stereo track. Output size MUST target `UcgMediaLimits.videoMaxBytes` (20MB); if first pass exceeds limit, client MAY retry with lower CRF or smaller scale before failing with user-visible error.

iOS/Android 上 `ucgUploadLocalVideo` MUST 对每条本地视频执行 ffmpeg 转码（不得因 ≤20MB 跳过）。输出 MUST 为 MP4：H.264 Main、yuv420p、≤15s、宽≤1280、30fps、faststart；无音轨 MUST 补静音 AAC。超出 20MB MUST 降参重试或失败提示。

#### Scenario: Small but non-compliant source still transcodes

- **WHEN** 用户上传 4MB 的 H.264 High 且 moov-at-end 源文件
- **THEN** Client SHALL 仍执行 ffmpeg normalize
- **AND** 上传 bytes MUST 使用 `transform_version` `v2`

#### Scenario: Silent source gains AAC track

- **WHEN** ffprobe 检测到源文件无 audio stream
- **THEN** normalize 输出 MUST 含 AAC 音轨（静音）

#### Scenario: Over-duration rejected before transcode

- **WHEN** 源视频时长 > 15 秒
- **THEN** Client SHALL 拒绝上传并提示超限
- **AND** MUST NOT 上传 raw 源文件

### Requirement: Web SHALL validate and upload raw video without client ffmpeg

On Web (`kIsWeb`), `ucgUploadLocalVideo` MUST validate MIME/duration/size then upload prepared bytes with `transform_version` `v1` without client-side ffmpeg or ffmpeg.wasm. Canonical MP4 normalize (same parameters as native v2) MUST be performed server-side (go_ai_talk backlog).

Web 端 MUST 校验后直传 raw（`transform_version` `v1`），不得使用客户端 ffmpeg/wasm；canonical 转码 MUST 由服务端异步完成（go_ai_talk backlog）。

#### Scenario: Web compose upload skips wasm

- **WHEN** Web 用户选择视频并发帖上传
- **THEN** Client SHALL 调用 `ucgUploadLocalVideo` Web 分支
- **AND** MUST NOT 加载 ffmpeg.wasm

#### Scenario: Web upload uses v1 transform version

- **WHEN** Web 端视频 upload register 完成
- **THEN** resolve/register MUST 携带 `transform_version` `v1`

### Requirement: Server-side video normalize backlog SHALL mirror native v2 output

The go_ai_talk service (out of Flutter repo scope) MUST eventually transcode Web-originated `transform_version` `v1` video blobs to the same canonical format as native v2: H.264 Main, AAC (silent if needed), faststart, ≤15s, ≤20MB target. Until server transcode completes, Flutter MAY show list thumbnail; inline playback MAY fail and MUST rely on `ucg-video-playback-fallback`.

go_ai_talk 服务端 MUST（后续实现）将 Web 来源 v1 视频转码为与 native v2 相同 canonical 格式；完成前 App 可展示封面，内联失败时可走播放兜底。

#### Scenario: Server transcode documented as Phase 2

- **WHEN** 评审本 Flutter change
- **THEN** tasks MUST 列出 go worker 为 Phase 2 backlog
- **AND** 本仓库 MUST NOT 阻塞于服务端已部署
