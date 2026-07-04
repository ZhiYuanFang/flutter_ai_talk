## ADDED Requirements

### Requirement: WeChat share title SHALL use debate topic content

When sharing a debate post to WeChat friends or moments via fluwx, the share title MUST be the post `content` (topic text). Moment posts SHALL keep existing share title rules.

fluwx 分享辩论帖时标题 MUST 为帖子 `content`（话题正文）。

#### Scenario: 好友分享标题

- **WHEN** 用户在辩论详情触发分享到微信好友
- **THEN** fluwx share payload title SHALL 等于 `post.content`

### Requirement: Share cover SHALL use client-rendered screenshot uploaded via UCG presign

The App MUST render an offscreen debate detail layout (topic, `UcgDebateVsBar`, optional argument snippets) into a PNG via `RenderRepaintBoundary`, upload bytes through the existing UCG presign + PUT OSS flow, and use the returned CDN URL as the WeChat share image URL. Server-side rendering MUST NOT be required for MVP.

App MUST 离屏渲染辩论详情截图，经 UCG presign 上传 OSS，将 CDN URL 用于 fluwx 分享图。

#### Scenario: 截图上传成功

- **WHEN** 用户分享辩论帖且 presign 与 PUT 成功
- **THEN** App SHALL 将 CDN URL 填入 fluwx 图片分享参数
- **AND** 好友与朋友圈分享 MUST 使用同一 URL

#### Scenario: 上传失败降级

- **WHEN** presign 或 PUT 失败
- **THEN** App SHALL 仍允许纯文字分享（无图）
- **AND** MUST 经 `AppDebugLog` 记录 `err=`（不得裸 `print`）

#### Scenario: 复用 presign 契约

- **WHEN** 客户端请求辩论分享图 presign
- **THEN** 请求 MUST 遵循既有 `POST /media/presign` 字段约定（contentType、后缀等）
