## ADDED Requirements

### Requirement: Chat UI SHALL display image message thumbnails from server mediaThumbnailUrl

Chat message bubbles and history lists MUST load image content via API `mediaThumbnailUrl` when rendering thumbnails or constrained previews; full-resolution `mediaCdnUrl` SHALL be used only when the user opens or expands the image. Video messages MUST NOT expect server `mediaThumbnailUrl`; chat video bubbles MUST show a client-extracted first-frame poster using the same approach as Feed video tiles.

#### Scenario: Chat bubble shows image thumb
- **WHEN** 聊天历史含图片消息且 API 返回 `mediaThumbnailUrl`
- **THEN** 气泡内图片预览 SHALL 加载 `mediaThumbnailUrl`
- **AND** Client MUST NOT 对 `mediaCdnUrl` 追加客户端 OSS 处理参数

#### Scenario: Chat video bubble shows client first-frame poster
- **WHEN** 聊天历史含视频消息且用户尚未点击播放
- **THEN** 气泡内 SHALL 在客户端本地提取视频首帧作为静态封面（与 Feed `UcgMomentsVideoTile` 同方案：可见时懒加载、滚出视口释放）
- **AND** Server MUST NOT 返回 `mediaThumbnailUrl`；Client MUST NOT 使用 OSS `video/snapshot`
- **AND** 用户点击后 SHALL 用完整 `mediaCdnUrl` 初始化播放器并开始播放
- **AND** 首帧提取失败时 SHALL 回退渐变占位与播放按钮

#### Scenario: Chat HTTP history exposes media thumb fields
- **WHEN** App 调用 `GET /conversations/{id}/messages`
- **THEN** 图片消息 JSON SHALL 含 `mediaCdnUrl` 与 `mediaThumbnailUrl`（经 ucg-service DTO 映射，HTTP 层不得剥离）

### Requirement: Chat avatars SHALL use avatarThumbnailUrl in list and bubbles

Conversation list rows, chat app bar, and message bubble avatars MUST use `avatarThumbnailUrl` / `peerAvatarThumbnailUrl` (or equivalent enriched field) for display; full `avatarUrl` MUST NOT be loaded on chat list surfaces.

#### Scenario: Message list peer avatar uses thumb
- **WHEN** `GET /conversations` 返回 `peerAvatarThumbnailUrl`
- **THEN** 消息列表行 SHALL 用缩略图 URL 展示对方头像

#### Scenario: Chat bubble sender avatar uses thumb
- **WHEN** 聊天页展示消息旁发送者头像
- **THEN** App SHALL 使用 profile / 会话 enrichment 的 `avatarThumbnailUrl`
- **AND** Client MUST NOT 在聊天气泡或 AppBar 加载全分辨率 `avatarUrl`
