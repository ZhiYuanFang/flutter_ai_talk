## Why

当前 UCG 发布流程从底部「+」直接进入全屏 compose，媒体选择与编辑混在同一页，缺少微信式「先选来源再编辑」的分层体验；草稿在 `dispose()` 中自动保存与显式「保存草稿 / 放弃」对话框冲突，且移除媒体后 OSS 对象成为孤儿；compose 页仍保留 inline 图片/视频 picker，与「入口 sheet 预选媒体 + 编辑页 9 宫格」的产品目标不符。同时用户希望在选图场景下获得 AI 润笔能力，需补齐服务端 vision 调用、媒体所有权追踪与 Admin 可配置模型。

## Cross-Repo Scope

本变更须 **Flutter 客户端与 go_ai_talk 后端同步推进**，不得仅改 `flutter_ai_talk` 单侧：

| 仓库 | 路径 | 职责 |
|------|------|------|
| **flutter_ai_talk** | `d:\work\flutter_ai_talk\app\lib\ucg\` | 入口 sheet、compose 9 宫格、草稿/关闭语义、delete/polish 客户端调用 |
| **go_ai_talk** | `d:\work\go_ai_talk\internal\services\ucg\` | 媒体 ownership 日志、OSS 删除、DeepSeek 润笔、AI 配置运行时 |
| **go_ai_talk** | `d:\work\go_ai_talk\internal\controller\`、`api/v1/` | App/Admin HTTP handlers 与 OpenAPI 路由注册 |
| **go_ai_talk** | `d:\work\go_ai_talk\manifest\config\config.ucg-service.yaml` | DeepSeek API Key 独立配置块 |
| **go_ai_talk** | `d:\work\go_ai_talk\resource\public\` | `admin.html` 入口卡片 + `ucg-admin.html` AI 配置页 |
| **go_ai_talk** | `d:\work\go_ai_talk\hack\config.yaml` | `gf gen dao` 新表注册 |
| **go_ai_talk** | gateway-app | 代理 `/ucg/app/api/*`（需登录）与 `/ucg/admin/api/*`（Admin 口令） |

**部署顺序**：先后端 DB migration + ucg-service API + gateway 代理 + Admin 页 → 再 Flutter compose 重构与联调。

## What Changes

### 后端 go_ai_talk（**不得跳过**）

- **数据库（`ai_voice_ucg`）**
  - 新表 `ucg_media_upload`（wx_id、object_key unique、media_kind、created_at）
  - 新表 `ucg_ai_config` 单例行 id=1（vision_model、max_images_per_request、updated_at、updated_by）+ seed 默认值
  - `hack/config.yaml` 注册两表 → `gf gen dao`
- **媒体 ownership 与删除**
  - `internal/services/ucg/oss_presign.go`、`oss_upload.go`：presign/同域 upload 成功路径写入 `ucg_media_upload`
  - 新建 `internal/services/ucg/oss_delete.go`：`DeleteOwnedMedia`（所有权校验、`ucg_post_media` 跳过、OSS 删除）
  - `POST /ucg/app/api/media/delete` — handler 于 `ucg_app_api.go` + `api/v1/ucg_app_http.go`
- **AI 润笔与配置**
  - 新建 `internal/services/ucg/ai_config.go`：DB/YAML 读取、~60s TTL 缓存、Admin PUT 失效
  - 新建 `internal/services/ucg/compose_ai.go`：DeepSeek vision 润笔（对齐 voice 模块 HTTP 模式）
  - `POST /ucg/app/api/posts/polish` — App handler
  - `manifest/config/config.ucg-service.yaml` 增加 `ucg.ai.deepseek_api_key` block；生产经 env `UCG_DEEPSEEK_API_KEY` 注入
- **Admin**
  - 新建 `internal/controller/ucg_admin_api.go` + `api/v1/ucg_admin_http.go`
  - `GET/PUT /ucg/admin/api/ai-config`（Header `X-Admin-Password`，env `UCG_ADMIN_PASSWORD`）
  - `resource/public/ucg-admin.html` + `admin.html` UCG 卡片入口
  - gateway-app 代理 `/ucg/admin/api/*` 至 ucg-service（或 ucg-service 自注册 Admin 路由，与现有 device admin 模式一致）
- **Gateway**
  - `POST /media/delete`、`POST /posts/polish` **不得**加入匿名白名单（须登录 JWT）
  - Admin API 走 `/ucg/admin/api/*` 口令鉴权

### Flutter 客户端

- **入口分流（`ucg-shell-navigation`）**
  - 短按「+」且无草稿：Bottom sheet →「拍摄」（照片/视频）或「从手机相册选择」→ 上传 → 进入 compose 并预填媒体。
  - 短按「+」且有草稿：跳过 sheet，直接进入 compose 并恢复草稿（完整编辑模式）。
  - 长按「+」：纯文字 compose 模式；若有草稿则恢复；隐藏媒体 picker UI（已有草稿媒体只读展示或可移除，不得新增媒体选择）。
- **Compose 页重构（`ucg-compose-post`）**
  - 移除标题字段，仅保留可编辑正文。
  - 9 宫格展示图片/视频；图片支持拖拽排序；拖至底部删除区移除。
  - compose 页可继续添加图片（不得替换/新增视频）；图片与视频互斥；最多 9 张图。
  - 沿用现有压缩策略（图片目标 10MB、视频目标 20MB、服务端硬上限 25MB、视频最长 15s）。
  - 视频选定后 compose 页不得替换；须通过关闭且不保存草稿后从 sheet 重选。
  - 「拍摄」路径支持相机拍照/录像（Web 可降级或隐藏）。
- **关闭与草稿（`ucg-compose-post`）**
  - 无内容（trim 后正文为空且无图无视频）：直接退出，无对话框。
  - 有内容：三选项对话框「保存草稿 / 放弃 / 取消」。
  - 保存草稿：写入 SharedPreferences，保留 OSS objectKey。
  - 放弃：清除草稿并删除本会话孤儿 OSS（调用 delete API）。
  - 修复 `dispose()` 自动保存与显式放弃/取消的冲突。
- **OSS 删除与所有权（`ucg-media-upload` + `ucg-api-contract`）**
  - 新表 `ucg_media_upload`：presign/上传成功时记录 wxId + objectKey。
  - 新 API `POST /ucg/app/api/media/delete`：校验所有权；若 key 已出现在 `ucg_post_media` 则跳过删除。
  - 客户端在：移除 chip、放弃 compose、视频重选流程中调用 delete。
- **AI 润笔（`ucg-compose-ai-polish` + `ucg-ai-config`）**
  - compose 页按钮，仅在有图片选中时显示（非纯视频、非纯文字）。
  - 新 API `POST /ucg/app/api/posts/polish`（或 `compose/ai-polish`）：DeepSeek vision，传入已上传图片 CDN URL。
  - API Key 配置于 ucg yaml/env（独立 block，初期从 voice 模块复制）。
  - Admin：`ucg_ai_config` 单例表 + `ucg-admin.html` 卡片 + `GET/PUT /ucg/admin/api/ai-config`；模型下拉硬编码 allowlist；运行时 ~60s TTL 缓存。
- **不在范围**
  - `updatePost` / 从 profile 编辑已有帖（后端已有，Flutter 未接入）。
  - Web 相机能力完整 parity（可降级隐藏）。

## Capabilities

### New Capabilities

- `ucg-media-upload`：媒体上传所有权日志、`ucg_media_upload` 表、孤儿 OSS 删除 API 与客户端调用契约。
- `ucg-ai-config`：UCG AI Admin 配置（DB 单例、Admin UI、GET/PUT API、运行时缓存与 YAML fallback）。
- `ucg-compose-ai-polish`：compose 页 AI 润笔按钮、客户端调用与服务端 DeepSeek vision 润笔流程。

### Modified Capabilities

- `ucg-compose-post`：入口分流后的 compose UX（9 宫格、拖拽排序/删除、互斥媒体、关闭三选项草稿、dispose 修复、AI 润笔入口条件）；与 keyboard 草稿 tension 的显式保存边界。
- `ucg-shell-navigation`：短按/长按「+」分流、bottom sheet 媒体来源、有草稿直达 compose。
- `ucg-api-contract`：新增 `POST /media/delete`、`POST /posts/polish`、Admin `GET/PUT /ai-config` 及 DTO/错误码约定。

## Impact

- **Flutter**（`d:\work\flutter_ai_talk`）：`ucg_shell.dart`（+ 手势与 sheet）、`ucg_compose_screen.dart`（大幅重构）、新建 compose 9-grid / delete-zone / sheet widgets；`ucg_repository.dart`、`ucg_compose_draft_store.dart`；`ucg_media_picker.dart`（相机/相册/sheet 编排）。
- **go_ai_talk — ucg-service**（`d:\work\go_ai_talk`）：
  - **新建**：`internal/services/ucg/oss_delete.go`、`ai_config.go`、`compose_ai.go`；`internal/controller/ucg_admin_api.go`；`api/v1/ucg_admin_http.go`；`resource/public/ucg-admin.html`
  - **修改**：`oss_presign.go`、`oss_upload.go`（ownership log）；`ucg_app_api.go`、`api/v1/ucg_app_http.go`（delete + polish）；`hack/config.yaml`；`manifest/config/config.ucg-service.yaml`；`resource/public/admin.html`；gateway 代理注册
  - **DDL**：`ucg_media_upload`、`ucg_ai_config`（`ai_voice_ucg`）
- **环境变量**：`UCG_DEEPSEEK_API_KEY`（润笔）、`UCG_ADMIN_PASSWORD`（Admin AI 配置页）；与现有 `UCG_SERVICE_BASE_URL`、gateway JWT 并存。
- **依赖**：现有 `image_picker`、压缩逻辑、`ManagedKeyboardTextField` / keyboard 确认条（`ucg-keyboard-input-enhancements` 基线保持）；新增服务端 DeepSeek HTTP 依赖（对齐 voice 模块 `internal/services/voice/` 模式）。
- **OpenSpec 基线**：`add-ucg-module` 中 `ucg-compose-post`、`ucg-shell-navigation`、`ucg-media-cdn`；`ucg-keyboard-input-enhancements` 中 compose blur/草稿 tension 条款需在 MODIFIED delta 中显式衔接。
