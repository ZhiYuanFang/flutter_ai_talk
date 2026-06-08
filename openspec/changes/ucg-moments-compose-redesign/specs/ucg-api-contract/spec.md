## ADDED Requirements

### Requirement: ucg-service SHALL implement media delete in go_ai_talk oss_delete.go

The delete flow MUST be implemented in `go_ai_talk/internal/services/ucg/oss_delete.go` as `DeleteOwnedMedia`, invoked by `UcgAppCtrl.MediaDelete` in `internal/controller/ucg_app_api.go`. Route registration MUST use OpenAPI struct tags in `api/v1/ucg_app_http.go` at path `POST /ucg/app/api/media/delete`. The handler MUST NOT be listed in gateway-app anonymous auth exempt prefixes.

媒体删除逻辑须位于 `go_ai_talk` ucg-service `oss_delete.go`；由 App controller 暴露；不得加入 gateway 匿名白名单。

#### Scenario: 服务层删除孤儿对象
- **WHEN** App handler 收到有效 JWT 用户的 delete 请求
- **THEN** `DeleteOwnedMedia` SHALL 校验 `ucg_media_upload.wx_id` 并删除未在 `ucg_post_media` 引用的 OSS 对象

### Requirement: ucg-service SHALL expose POST /media/delete for owned orphan objects

The ucg-service MUST provide `POST /ucg/app/api/media/delete` accepting authenticated requests with body `{ "objectKeys": string[] }`. For each key, the service MUST verify ownership via `ucg_media_upload.wx_id == caller wxId`. If the key exists in `ucg_post_media`, the service MUST skip deletion for that key. Otherwise the service MUST delete the OSS object and remove the `ucg_media_upload` row. Response MUST include lists of deleted and skipped keys.

ucg-service 必须提供媒体删除 API；校验所有权；已发帖引用的 key 须跳过；否则删除 OSS 与 upload 记录。

#### Scenario: 删除自有孤儿对象
- **WHEN** 已登录用户请求删除其 `ucg_media_upload` 中拥有且未在 `ucg_post_media` 引用的 objectKey
- **THEN** 服务 SHALL 删除 OSS 对象
- **AND** 响应 `deleted` SHALL 包含该 key

#### Scenario: 已发帖 media 跳过
- **WHEN** objectKey 已存在于 `ucg_post_media`
- **THEN** 服务 SHALL NOT 删除 OSS
- **AND** 响应 `skipped` SHALL 包含该 key

#### Scenario: 非所有者拒绝
- **WHEN** 用户请求删除他人 upload 记录中的 objectKey
- **THEN** 服务 SHALL NOT 删除
- **AND** 该 key SHALL 出现在 `skipped` 或错误明细中

### Requirement: ucg-service SHALL implement polish in go_ai_talk compose_ai.go

The polish flow MUST be implemented in `go_ai_talk/internal/services/ucg/compose_ai.go` as `PolishPostText`, reading model settings via `internal/services/ucg/ai_config.go` `LoadAIConfig`. Route registration MUST use `api/v1/ucg_app_http.go` at path `POST /ucg/app/api/posts/polish`. DashScope API key MUST be read from `manifest/config/config.ucg-service.yaml` block `ucg.ai.dashscope_api_key` with env override `UCG_DASHSCOPE_API_KEY`.

润笔逻辑须位于 `compose_ai.go`；配置经 `ai_config.go`；API Key 来自 ucg yaml/env。

#### Scenario: 配置来源
- **WHEN** ucg-service 处理 polish 请求
- **THEN** 服务 SHALL 使用 `LoadAIConfig` 返回的 visionModel 与 maxImagesPerRequest
- **AND** DashScope HTTP 调用 SHALL 使用 env `UCG_DASHSCOPE_API_KEY` 或 yaml `ucg.ai.dashscope_api_key`

### Requirement: ucg-service SHALL expose POST /posts/polish for AI text polish

The ucg-service MUST provide `POST /ucg/app/api/posts/polish` accepting `{ "imageKeys": string[], "text"?: string }`. The service MUST resolve imageKeys to CDN URLs, load vision model settings from `ucg_ai_config`, enforce `max_images_per_request`, call DashScope Qwen vision via an OpenAI-compatible endpoint, and return `{ "polishedText": string }`. Request MUST require authenticated session.

必须提供 AI 润笔接口；将 imageKeys 转为 CDN URL；读取 AI 配置；调用 DashScope Qwen vision；返回润笔正文。

#### Scenario: 润笔成功
- **WHEN** 客户端提交有效 imageKeys 与可选 text
- **THEN** 响应 SHALL 返回非空 `polishedText`

#### Scenario: 超过 max_images_per_request
- **WHEN** imageKeys 数量超过配置上限
- **THEN** 服务 SHALL 返回 400 及可读错误信息

#### Scenario: AI 未配置
- **WHEN** DashScope API key 未配置
- **THEN** 服务 SHALL 返回 503

### Requirement: ucg-admin SHALL implement ai-config in go_ai_talk ucg_admin_api.go

Admin AI config MUST be implemented in `go_ai_talk/internal/controller/ucg_admin_api.go` with route structs in `api/v1/ucg_admin_http.go`. Authentication MUST use Header `X-Admin-Password` validated against env `UCG_ADMIN_PASSWORD` (or yaml `ucg.admin.password`). Admin static UI MUST live at `resource/public/ucg-admin.html` with entry card on `resource/public/admin.html`. Gateway MUST proxy `/ucg/admin/api/*` to ucg-service.

Admin AI 配置须由 ucg_admin_api 实现；静态页 ucg-admin.html；gateway 代理 Admin 前缀。

#### Scenario: Admin 路由与鉴权
- **WHEN** 客户端请求 `GET /ucg/admin/api/ai-config` 无有效口令
- **THEN** ucg-service SHALL 返回 401

#### Scenario: gateway Admin 代理
- **WHEN** 请求经 gateway-app 访问 `/ucg/admin/api/ai-config`
- **THEN** gateway SHALL 转发至 ucg-service Admin handler

### Requirement: ucg-admin SHALL expose GET/PUT /ai-config

The ucg admin API MUST provide `GET /ucg/admin/api/ai-config` and `PUT /ucg/admin/api/ai-config` for singleton row `ucg_ai_config` (id=1) fields: `visionModel`, `maxImagesPerRequest`, `updatedAt`, `updatedBy`. PUT MUST validate `visionModel` against a hardcoded server-side allowlist.

Admin 须提供 AI 配置读写；PUT 须校验模型 allowlist。

#### Scenario: 读取 AI 配置
- **WHEN** Admin 请求 GET ai-config
- **THEN** 响应 SHALL 返回当前 visionModel 与 maxImagesPerRequest

#### Scenario: 更新 AI 配置
- **WHEN** Admin PUT 合法 visionModel 与 maxImagesPerRequest
- **THEN** 服务 SHALL 持久化并 invalidate 运行时缓存

#### Scenario: 非法模型拒绝
- **WHEN** Admin PUT 不在 allowlist 的 visionModel
- **THEN** 服务 SHALL 返回 400

### Requirement: UcgRepository SHALL call deleteMedia and polishPost

`UcgRepository` / `UcgApiClient` MUST expose `deleteMedia({required List<String> objectKeys})` and `polishPost({required List<String> imageKeys, String? text})` calling the canonical gateway-prefixed endpoints with existing envelope decode.

Flutter 仓库层必须封装 delete 与 polish API。

#### Scenario: 客户端删除媒体
- **WHEN** compose 移除图片或放弃草稿
- **THEN** Client SHALL 调用 `POST /ucg/app/api/media/delete`

#### Scenario: 客户端润笔
- **WHEN** 用户点击 AI 润笔
- **THEN** Client SHALL 调用 `POST /ucg/app/api/posts/polish`

#### Scenario: presign 路径不变
- **WHEN** 客户端上传媒体
- **THEN** Client SHALL 继续使用 `POST /ucg/app/api/media/presign` 与既有直传流程
