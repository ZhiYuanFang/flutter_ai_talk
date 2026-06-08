## ADDED Requirements

### Requirement: Compose AI polish action SHALL be visible only with images

The compose screen MUST render an「AI润笔」control only when `_imageKeys.isNotEmpty` and no video is selected. The control MUST be hidden during text-only entry mode and video-only sessions.

「AI润笔」仅在有图片且无视频时显示；纯文字入口与纯视频会话须隐藏。

#### Scenario: 有图显示按钮
- **WHEN** compose 页至少有一张已上传图片且未选视频
- **THEN** UI SHALL 显示「AI润笔」

#### Scenario: 视频模式隐藏
- **WHEN** compose 页仅含视频
- **THEN** UI SHALL NOT 显示「AI润笔」

#### Scenario: 纯文字入口隐藏
- **WHEN** 用户通过长按「+」进入 text-only compose
- **THEN** UI SHALL NOT 显示「AI润笔」（即使草稿含图，text-only 模式无新选图时不显示 — 若草稿含图则按有图规则显示）

#### Scenario: 草稿含图长按入口
- **WHEN** 用户长按「+」且恢复的草稿含 imageKeys
- **THEN** UI SHALL 显示「AI润笔」（因存在已选图片）

### Requirement: AI polish SHALL send CDN URLs derived from uploaded image keys

The client MUST call `POST /ucg/app/api/posts/polish` with `imageKeys` currently selected in compose order and optional current body `text`. The server MUST convert keys to CDN URLs via fixed CDN base (`ucg-media-cdn` helper) before DashScope Qwen vision invocation using OpenAI-compatible multimodal messages (`image_url` parts first, then `text` part; no separate system role).

润笔请求须提交 compose 内 imageKeys 顺序与可选正文；服务端须将 key 转为 CDN URL 再调用 DashScope Qwen vision（OpenAI 兼容多模态格式；先图后文）。

#### Scenario: 请求含 keys 与正文
- **WHEN** 用户点击「AI润笔」
- **THEN** Client SHALL POST imageKeys 与当前正文 text

#### Scenario: 服务端 vision 输入
- **WHEN** `go_ai_talk/internal/services/ucg/compose_ai.go` 处理 polish 请求
- **THEN** vision 调用 SHALL 使用 `BuildCdnURL` 生成的公网 CDN URL 列表（非 raw objectKey）
- **AND** 请求体 messages user content SHALL 为 multimodal array（`type: image_url` 在前，`type: text` 在后）
- **AND** 默认 text 文案 SHALL 为「作为宝宝家长，你正在发朋友圈，选择了这些图，说点什么吧。」（有草稿时附带草稿上下文）

### Requirement: AI polish result SHALL update compose body text

On successful polish response, the client MUST replace the compose body controller text with `polishedText` and allow further manual editing. The client MUST show loading state while the request is in flight and MUST surface API errors via snackbar or dialog.

润笔成功须用 polishedText 更新正文并允许继续编辑；请求中须 loading；失败须提示。

#### Scenario: 成功更新正文
- **WHEN** API 返回 polishedText
- **THEN** compose 正文 SHALL 更新为该文本

#### Scenario: 请求中禁用重复点击
- **WHEN** 润笔请求进行中
- **THEN** 「AI润笔」按钮 SHALL 禁用或显示 loading

#### Scenario: API 失败提示
- **WHEN** polish API 返回错误
- **THEN** App SHALL 展示可读错误信息且保留用户原正文

### Requirement: Server polish SHALL respect max_images_per_request from ucg_ai_config

The polish handler MUST truncate or reject imageKeys count exceeding `ucg_ai_config.max_images_per_request`. Vision model name MUST come from `ucg_ai_config.vision_model`.

服务端须 enforce max_images_per_request；须使用配置的 vision_model。

#### Scenario: 截断或拒绝超限
- **WHEN** 请求 imageKeys 数量大于 max_images_per_request
- **THEN** 服务 SHALL 返回 400 或仅处理前 N 张（实现须与 API 契约一致；本变更默认 400 拒绝）

#### Scenario: 使用配置模型
- **WHEN** 执行 DashScope Qwen vision 调用
- **THEN** 服务 SHALL 使用 ucg_ai_config.vision_model
