## ADDED Requirements

### Requirement: Chat local video attachment upload SHALL use ucgUploadLocalVideo

When the user sends a chat message with a locally picked video, the client MUST upload media through `ucgUploadLocalVideo` before posting the message with `videoKey`. Chat MUST NOT upload unprepared raw video bytes.

用户发送聊天本地视频时，客户端 MUST 经 `ucgUploadLocalVideo` 上传后再携带 `videoKey` 发消息；MUST NOT 上传未 normalize 的 raw 视频。

#### Scenario: Chat pick then send normalizes video

- **WHEN** 用户在聊天中选择本地视频并发送
- **THEN** Client SHALL 调用 `ucgUploadLocalVideo` 获取 objectKey
- **AND** native 路径 MUST 使用 `transform_version` `v2`
