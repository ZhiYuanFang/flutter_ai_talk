## MODIFIED Requirements

### Requirement: Compose AI polish action SHALL be visible only with images

The compose screen MUST render an「AI润笔」control whenever at least one image slot exists and no video is selected. The control MUST remain visible during background upload. The control MUST be hidden in text-only entry mode and when a video slot is present.

「AI润笔」须在「有图片且无视频」时显示，后台上传期间不得隐藏。

#### Scenario: 有图显示按钮
- **WHEN** compose 页至少有一张图片（含仅本地预览未上传）
- **THEN** UI SHALL 显示「AI润笔」

#### Scenario: 上传中仍显示
- **WHEN** 图片仍在后台上传
- **THEN** UI SHALL 仍显示「AI润笔」

#### Scenario: 视频模式隐藏
- **WHEN** compose 页含视频 slot
- **THEN** UI SHALL NOT 显示「AI润笔」

### Requirement: AI polish result SHALL update compose body text

On user tap, the client MUST show in-button loading on the「AI润笔」control, await all image uploads to complete, then call `POST /ucg/app/api/posts/polish` with uploaded `imageKeys` in compose order. Upload wait and polish request MUST share the same button loading state without separate progress UI. On success, replace body text with `polishedText`.

点击润笔须在按钮内转圈，先等待全部图片上传完成再调 polish API；上传等待与润笔请求共用同一 loading。

#### Scenario: 润笔前等待上传
- **WHEN** 用户点击「AI润笔」且存在未完成上传的图片
- **THEN** 「AI润笔」按钮内 SHALL 显示 loading
- **AND** App SHALL await 全部图片上传完成后才发起 polish 请求

#### Scenario: 成功更新正文
- **WHEN** polish API 返回 polishedText
- **THEN** compose 正文 SHALL 更新为该文本

#### Scenario: 请求中禁用重复点击
- **WHEN** 润笔 loading 进行中（含等待上传）
- **THEN** 「AI润笔」按钮 SHALL 禁用重复点击

#### Scenario: API 失败提示
- **WHEN** polish API 返回错误
- **THEN** App SHALL 展示可读错误且保留用户原正文
