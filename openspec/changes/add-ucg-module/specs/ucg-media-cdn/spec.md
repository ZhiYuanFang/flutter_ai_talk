## ADDED Requirements

### Requirement: Media URLs SHALL be built from objectKey and fixed CDN base

The app SHALL store and transmit OSS `objectKey` only in DTOs/local draft. Display URLs MUST be constructed as `https://resorce.cuplay.top/{objectKey}` via a single helper (e.g. `UcgMediaUrl.objectKeyToCdn`).

#### Scenario: 展示帖子图片
- **WHEN** Feed 返回 `objectKey` 为 `social/2026/06/abc.jpg`
- **THEN** Image widget SHALL load `https://resorce.cuplay.top/social/2026/06/abc.jpg`

#### Scenario: 上传后仅存 objectKey
- **WHEN** presign 上传完成
- **THEN** App SHALL 在发帖请求 body 中仅提交 objectKey，且 SHALL NOT 持久化完整 CDN URL 到 draft JSON 作为权威字段（可缓存派生 URL）
