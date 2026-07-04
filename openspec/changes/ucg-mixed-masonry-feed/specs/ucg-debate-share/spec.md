## MODIFIED Requirements

### Requirement: Share cover SHALL use client-rendered screenshot uploaded via UCG presign

The App MUST render an offscreen debate detail layout (topic, `UcgDebateVsBar` with macaron fake-glass styling, optional argument snippets) wrapped in the same `UcgFeedFakeGlassPanel` visual as square feed cards, into a PNG via `RenderRepaintBoundary`, upload bytes through the existing UCG presign + PUT OSS flow, and use the returned CDN URL as the WeChat share image URL. The offscreen layout MUST NOT use a plain white full-bleed background disconnected from in-app feed styling.

App MUST 离屏渲染与 Feed 一致的假玻璃卡 + 可爱 VS 条截图，经 presign 上传。

#### Scenario: 截图上传成功

- **WHEN** 用户分享辩论帖且 presign 与 PUT 成功
- **THEN** App SHALL 将 CDN URL 填入 fluwx 图片分享参数
- **AND** 分享图 MUST 包含假玻璃卡边框与马卡龙 VS 条

#### Scenario: 上传失败降级

- **WHEN** presign 或 PUT 失败
- **THEN** App SHALL 仍允许纯文字分享（无图）
- **AND** MUST 经 `AppDebugLog` 记录 `err=`

#### Scenario: 分享图与 App 内卡片一致

- **WHEN** 用户对比 App 内广场辩论卡与生成的分享 PNG
- **THEN** 两者 MUST 使用同一 VS 条组件与假玻璃 panel token
