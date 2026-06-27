## ADDED Requirements

### Requirement: History square sync local video upload SHALL use ucgUploadLocalVideo

When saving a history record with「同步广场」enabled and a new local video in media, the client MUST upload that video via `ucgUploadLocalVideo` before `createPost`/`updatePost`.

喂养历史开启「同步广场」且含新本地视频时，客户端 MUST 经 `ucgUploadLocalVideo` 上传后再调用 `createPost`/`updatePost`。

#### Scenario: Sync square upload normalizes local video

- **WHEN** 用户在历史编辑 Sheet 保存且同步广场开启、媒体含本地视频 path
- **THEN** `_uploadHistoryMedia`（或等价） MUST 调用 `ucgUploadLocalVideo`
- **AND** MUST NOT 单独调用 `ucgPrepareVideoBytes`
