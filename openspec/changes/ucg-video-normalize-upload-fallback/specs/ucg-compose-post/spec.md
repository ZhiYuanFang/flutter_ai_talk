## ADDED Requirements

### Requirement: Compose video slot upload SHALL use ucgUploadLocalVideo

When a compose video slot uploads from `localPath`, the client MUST invoke `ucgUploadLocalVideo` inside the slot upload pipeline. While normalize runs, the slot MUST expose a preparing state distinct from uploading so UI can show「正在处理视频…」.

compose 视频槽从 `localPath` 上传时 MUST 调用 `ucgUploadLocalVideo`；normalize 期间 MUST 有 preparing 状态，UI 可展示「正在处理视频…」。

#### Scenario: Background slot upload normalizes before OSS

- **WHEN** compose 视频槽后台上传开始且 `localPath` 有效
- **THEN** Client SHALL 经 `ucgUploadLocalVideo` 完成 normalize 与 upload
- **AND** MUST NOT 使用旧 `ucgPrepareVideoBytes` 早退逻辑

#### Scenario: Preparing state visible during ffmpeg

- **WHEN** native ffmpeg normalize 进行中
- **THEN** 槽位状态 MUST 为 preparing 或等价语义
- **AND** 完成后 SHALL 进入 uploading/done
