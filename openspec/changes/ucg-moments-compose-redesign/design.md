## Context

UCG 发布页（`UcgComposeScreen`）当前行为：底部「+」直接 `Navigator.push` 全屏 compose；页面内同时提供正文输入与「添加图片 / 添加视频」chip；`dispose()` 无条件 `unawaited(_persistDraft())`，与用户期望的显式「保存草稿 / 放弃」冲突。草稿存于 SharedPreferences（`ucg_compose_draft_v1`），字段含 text、imageKeys、videoKey。媒体经 `POST /ucg/app/api/media/presign` 直传 OSS，客户端压缩对齐 `UcgMediaLimits`（图 10MB 目标、视频 20MB、服务端 25MB 硬 cap、视频 ≤15s）。

`ucg-keyboard-input-enhancements` 已规定 compose 正文 `scene: ucg.compose.body`：失焦 soft-sync 不写本地草稿，仅 `onConfirm` 触发 `_persistDraft`。本次 redesign 将**显式退出对话框**作为草稿持久化的主路径，并移除 `dispose()` 自动保存。

后端（go_ai_talk ucg-service）尚无媒体所有权表与 delete/polish API；Admin 无 UCG AI 配置页。voice 模块已有 DeepSeek/API Key 配置模式（`internal/services/voice/voice_chat.go`、`manifest/config/voice-chat.shared.yaml`）可复用 HTTP 调用结构。

**范围**：`d:\work\flutter_ai_talk\app\lib\ucg\` + `d:\work\go_ai_talk` ucg-service + gateway-app Admin 代理。

## Goals / Non-Goals

**Goals:**

- 微信式发布入口：sheet 选来源 → 上传 → compose 编辑；有草稿跳过 sheet；长按纯文字模式。
- Compose 9 宫格：拖拽排序、拖至删除区移除、页内可加图（不可换视频）。
- 关闭语义：空内容直退；有内容三选项；放弃时清理孤儿 OSS。
- 服务端媒体 ownership + delete API；polish API + Admin AI 配置。
- 与 keyboard 草稿 tension 一致：仅显式保存 / 确认条「确定」/ 发布成功 写入 SharedPreferences。

**Non-Goals:**

- Flutter 接入 `updatePost` / profile 编辑已有帖。
- Web 相机完整能力（可隐藏「拍摄」或降级为相册-only）。
- 自定义贴纸、非 DeepSeek 多模型路由（首版 Admin allowlist 硬编码下拉）。
- 自动化测试文件（按仓库规则）。

## Decisions

### 1. 入口状态机（`UcgShell`）

```text
Tap + ──► hasDraft? ──yes──► Compose(full, restore draft)
              │
              no
              ▼
         BottomSheet(拍摄 | 从相册选择)
              │
              ├── 拍摄 ──► CameraCaptureSheet(photo | video) ──► upload ──► Compose(preloaded)
              └── 相册 ──► pick multi/single ──► upload ──► Compose(preloaded)

Long-press + ──► Compose(textOnly: true, restore draft if any)
```

- `hasDraft`：`UcgComposeDraftStore.load()` 非 null 且非空（text trim 非空或 imageKeys 非空或 videoKey 非空）。
- `textOnly` compose：隐藏 sheet 内媒体入口与页内「添加图片/视频」；若草稿含媒体，9 宫格只读 + 允许 remove chip（remove 触发 delete API）。
- 短按有草稿：**不**展示 sheet，避免覆盖用户未完成内容。

**备选**：有草稿仍展示 sheet — 拒绝，与「恢复草稿」产品语义冲突。

### 2. Bottom sheet 与上传编排

新建 `UcgComposeEntrySheet`（或同级 widget）：

| 选项 | 行为 |
|------|------|
| 拍摄 | `ImagePicker` `ImageSource.camera`（photo）或 `pickVideo(source: camera)`；Web 不可用则隐藏或 toast |
| 从手机相册选择 | 多图（≤9）或单视频；互斥校验在 picker 层 |

上传完成后 push `UcgComposeScreen(initialMedia: ...)`，**不再**在 compose 页首次展示 sheet。

`UcgComposeScreen` 构造参数扩展：

```dart
UcgComposeScreen({
  this.editingPost,
  this.initialImageKeys,
  this.initialVideoKey,
  this.textOnly = false,
})
```

### 3. 9 宫格与拖拽删除

- 布局：`GridView` 3×3，`maxImages = 9`；视频占 1 格全宽预览（或单格 + 播放 icon）。
- 排序：Flutter `ReorderableGridView` 或 `LongPressDraggable` + `DragTarget` 自定义；仅图片可 reorder。
- 删除区：compose 底部固定 `UcgComposeDeleteZone`；drag over 高亮；drop 触发 remove + `deleteMedia(objectKey)` + 更新 draft 内存态（不自动写 SP，除非用户点保存草稿或确认条确定）。
- 页内「添加图片」：仅当非 video 模式且 `< 9` 张；调用 gallery multi-pick，**不得**打开 video picker。

### 4. 视频不可在 compose 内替换

- 有 `_videoKey` 时隐藏「添加视频」与 sheet 重入；用户点移除视频 → delete API → 清空 key（仍不可在 compose 内选新视频，需关闭且不保存草稿后从 shell 重走 sheet）。
- **规格明确**：移除后 compose 内仅可添加图片，不可添加新视频（除非退出重进 sheet 选视频）。

**决策**：移除视频后 compose 进入「仅图片/文字」模式，新视频必须放弃当前会话从入口 sheet 选择 — 简化状态机，避免半路上传冲突。

### 5. 关闭 / 草稿 / dispose 修复

```dart
bool get _hasContent =>
  _text.text.trim().isNotEmpty ||
  _imageKeys.isNotEmpty ||
  (_videoKey != null && _videoKey!.isNotEmpty);

Future<bool> _onCloseRequested() async {
  if (!_hasContent) return true; // pop without dialog
  final action = await showDialog<ComposeExitAction>(...); // 保存草稿 | 放弃 | 取消
  switch (action) {
    case saveDraft: await _persistDraft(); return true;
    case discard: await _discardSession(); return true;
    case cancel: return false;
  }
}
```

- `PopScope` / leading close 均走 `_onCloseRequested`。
- **`dispose()` 不得调用 `_persistDraft()`**；移除现有 `unawaited(_persistDraft())`。
- `_discardSession()`：`draftStore.clear()` + 对本 session 跟踪的 orphan keys 批量 `deleteMedia`（见决策 6）。
- 发布成功：clear draft + 不 delete 已提交 keys（server 已关联 post）。

与 keyboard tension：`onConfirm` 仍可 `_persistDraft()`（用户显式确认正文）；失焦 soft-sync 仍不写 SP（保持 `ucg-keyboard-input-enhancements`）。

### 6. Session orphan key 跟踪

Compose state 维护 `_sessionUploadedKeys: Set<String>`：每次 presign 上传成功 add；remove chip / discard 时 delete 并 remove from set；发布成功保留 keys（不 delete）。

Draft JSON 仅存 objectKeys；restore 时 `_sessionUploadedKeys` 初始化为 draft 内 keys（视为已拥有，放弃时仍可调 delete — server 跳过已发帖 media）。

### 7. `ucg_media_upload` 表与 delete API

**表结构（示意）**：

| 列 | 说明 |
|----|------|
| id | PK |
| wx_id | 上传者 |
| object_key | OSS key，唯一索引 |
| media_kind | 1=image 2=video |
| created_at | |

**presign 成功路径**：insert row（wxId 来自 JWT）。

**`POST /ucg/app/api/media/delete`**：

- Body: `{ "objectKeys": ["social/..."] }`（支持批量）
- Auth: 必须登录
- 逻辑：每条 key 校验 `ucg_media_upload.wx_id == caller`；若存在 `ucg_post_media.object_key` 则 **skip**（200 部分成功或 silent skip）；否则删 OSS + 删 upload row
- 响应：`{ "deleted": [...], "skipped": [...] }`

Flutter：`UcgRepository.deleteMedia({required List<String> objectKeys})`。

### 8. AI 润笔 API

**`POST /ucg/app/api/posts/polish`**

- Request: `{ "imageKeys": ["..."], "text": "用户当前正文" }`（text 可选，供 contextual polish）
- Server：objectKey → CDN URL（`https://resorce.cuplay.top/{key}`）；读取 `ucg_ai_config`（vision_model, max_images_per_request）；截断 imageKeys；调用 DashScope Qwen vision（OpenAI 兼容 `POST .../chat/completions`，多模态 content：**先** `image_url` **后** `text`）
- Response: `{ "polishedText": "..." }`
- 错误：429/502 友好 message；未配置 key 时 503

**配置**：

- YAML/env：`ucg.ai.dashscope_api_key`（DashScope Key，**非** DeepSeek/SiliconFlow）；`vision_endpoint` 默认 `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`
- DB `ucg_ai_config` id=1：vision_model, max_images_per_request, updated_at, updated_by
- Runtime：内存 cache TTL 60s；Admin PUT 后 invalidate

**Admin**：

- `admin.html` 增加 UCG 卡片 → `ucg-admin.html`
- `GET/PUT /ucg/admin/api/ai-config`
- Model dropdown 硬编码 allowlist（`qwen3-vl-plus`、`qwen3-vl-flash`、`qwen-vl-plus`、`qwen-vl-max` 等；历史 VL2 变体可选保留），PUT 校验

### 9. Compose AI 润笔 UX

- 按钮位于正文区下方或 app bar 旁；`visible = _imageKeys.isNotEmpty && !_uploadingMedia`
- 点击：取当前 `_text.text` + `_imageKeys` → `repository.polishPost(...)` → 替换或 append 至 controller（**决策**：replace 全文，用户可 undo 仅依赖系统 — 首版 replace + snackbar「已润笔，可继续编辑」）
- Loading 态 disable 发布与关闭或允许取消请求

### 10. 拍摄与平台差异

- iOS/Android：`image_picker` camera source
- Web：隐藏「拍摄」或 disabled + tooltip「请使用相册」— 实现期按 `kIsWeb` 分支

## go_ai_talk 架构（ucg-service）

### 数据库（`ai_voice_ucg`）

| 表 | 用途 | 关键列 |
|----|------|--------|
| `ucg_media_upload` | presign/upload 所有权审计 | `wx_id`（索引）、`object_key`（UNIQUE）、`media_kind`（1=image 2=video）、`created_at` |
| `ucg_ai_config` | AI 运行时单例配置 | `id=1`、`vision_model`、`max_images_per_request`、`updated_at`、`updated_by` |

- DDL 以 SQL migration 或运维脚本落地（与现有 `ucg_notification` 等表同库 `ai_voice_ucg`）。
- 部署后 `hack/config.yaml` ucg 域 `tables` 追加 `ucg_media_upload, ucg_ai_config` → 在 `go_ai_talk` 根目录执行 `gf gen dao` 生成 `internal/dao/`、`internal/model/`。

### 服务层文件（`internal/services/ucg/`）

| 文件 | 动作 | 职责 |
|------|------|------|
| `oss_presign.go` | **修改** | `PresignUpload` 成功后 insert `ucg_media_upload`（wxId 来自 caller context） |
| `oss_upload.go` | **修改** | `UploadMediaObject`（Web 同域代理）成功后同样写 ownership row |
| `oss_delete.go` | **新建** | `DeleteOwnedMedia(ctx, wxID, objectKeys)` → 查 ownership → 查 `ucg_post_media` skip → OSS DeleteObject → 删 upload row |
| `ai_config.go` | **新建** | `LoadAIConfig`：读 `ucg_ai_config` id=1 + YAML fallback；`InvalidateAIConfigCache`；TTL ~60s |
| `compose_ai.go` | **新建** | `PolishPostText(ctx, imageKeys, text)` → CDN URL（`oss_cdn.go` / `BuildCdnURL`）→ DashScope Qwen vision chat（OpenAI 兼容 multimodal；images 在前、text 在后；无 system role） |
| `oss_cdn.go` | 复用 | objectKey → CDN URL，供 polish vision 输入 |

### App HTTP（经 gateway `/ucg/app/api/*`）

| 路由 | 文件 | 说明 |
|------|------|------|
| `POST /ucg/app/api/media/delete` | `ucg_app_api.go` + `api/v1/ucg_app_http.go` | 需 JWT（`X-Internal-Wx-Id`）；**非**匿名白名单 |
| `POST /ucg/app/api/posts/polish` | 同上 | 需 JWT；503 当 DashScope key 未配置 |

- 路由注册：`internal/controller/register_ucg_service.go` 经 `group.Bind(NewUcgAppCtrl())` 自动绑定 OpenAPI struct tags。
- gateway 代理：`internal/controller/ucg_route_proxy.go` 已代理 `/ucg/app/api/*`；新端点无需额外 gateway handler，但 **不得** 加入 `gateway_app_auth_exempt.go` 匿名白名单。

### Admin HTTP + UI

| 路由 | 文件 | 说明 |
|------|------|------|
| `GET /ucg/admin/api/ai-config` | `ucg_admin_api.go` + `api/v1/ucg_admin_http.go` | Header `X-Admin-Password` |
| `PUT /ucg/admin/api/ai-config` | 同上 | 校验 `visionModel` allowlist；成功后 `InvalidateAIConfigCache` |
| `ucg-admin.html` | `resource/public/ucg-admin.html` | 模型下拉（硬编码 allowlist）、maxImagesPerRequest 表单 |
| `admin.html` | `resource/public/admin.html` | 新增 UCG 卡片链接 → `ucg-admin.html` |

- Admin 路由注册：ucg-service `RegisterUcgServiceHTTP` 增加 `group.Bind(NewUcgAdminCtrl())`；gateway-app 增加 `/ucg/admin/api/*` 反向代理（对齐 `/ucg/app/api/*` 模式，或 ucg-service 独立暴露 Admin 端口由 gateway 转发）。
- 口令：env `UCG_ADMIN_PASSWORD`（或 yaml `ucg.admin.password`），与 device admin `X-Admin-Password` 模式一致。

### 配置（`manifest/config/config.ucg-service.yaml`）

```yaml
ucg:
  ai:
    dashscope_api_key: ""          # 阿里云 DashScope Key（非 DeepSeek/SiliconFlow）；env UCG_DASHSCOPE_API_KEY 可覆盖
    vision_endpoint: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    default_vision_model: "qwen3-vl-plus"
    default_max_images_per_request: 9
  admin:
    password: ""                  # 生产用 env UCG_ADMIN_PASSWORD 覆盖
```

- 润笔 user message 默认文案：`作为宝宝家长，你正在发朋友圈，选择了这些图，说点什么吧。`（有草稿时附带草稿上下文）
- `LoadAIConfig`：DB row 优先 → YAML defaults → 空 key 时 polish 返回 503。

## 部署与配置

| 变量 / 配置 | 服务 | 用途 |
|-------------|------|------|
| `UCG_DASHSCOPE_API_KEY` | ucg-service | Qwen vision 润笔 API Key（覆盖 yaml `ucg.ai.dashscope_api_key`；兼容旧 env `UCG_DEEPSEEK_API_KEY`） |
| `UCG_ADMIN_PASSWORD` | ucg-service / gateway | Admin `GET/PUT /ucg/admin/api/ai-config` 口令 |
| `UCG_SERVICE_BASE_URL` | gateway-app | 已有；代理 App/Admin API 至 ucg-service |
| `GATEWAY_APP_JWT_SECRET` | ucg-service | 已有；App API JWT 校验 |
| `UCG_DB_LINK` / `MYSQL_TCP_HOST` | ucg-service | 已有；`ai_voice_ucg` 连接 |

**上线 checklist**：

1. 执行 DDL（两表 + seed `ucg_ai_config` id=1）
2. `gf gen dao` 提交生成的 dao/model
3. 部署 ucg-service（含新 handlers + yaml/env）
4. 部署 gateway-app（Admin 代理路由若新增）
5. 发布 `ucg-admin.html` + `admin.html` 卡片
6. Flutter 联调 delete/polish

## Risks / Trade-offs

- **[Risk] dispose 移除自动保存导致进程被杀丢失未确认内容** → 有内容关闭时必须走对话框；keyboard 确认条「确定」仍可写 SP；产品接受与微信一致。
- **[Risk] delete API 与已发帖 media 竞态** → server 强制查 `ucg_post_media`，已引用则 skip。
- **[Risk] 拖拽排序在 Web 体验差** → 首版仍提供 remove 按钮 fallback；Web 可弱化 drag 仅保留删除区 + 长按菜单排序。
- **[Risk] Qwen vision 成本与延迟** → Admin `max_images_per_request` 限制；客户端 polish 前校验 ≤9 图；CDN 图片须公网可访问供 DashScope 拉取。
- **[Risk] 视频移除后不能 compose 内重选造成困惑** → copy 提示「更换视频请关闭并重新选择」。
- **[Trade-off] session orphan set 与 draft restore** → 放弃时 delete draft 内全部 keys（server 保护已发帖）；实现简单。

## Migration Plan

1. **go_ai_talk DB**：`ucg_media_upload`、`ucg_ai_config` DDL + seed → `hack/config.yaml` → `gf gen dao`。
2. **go_ai_talk 服务层**：`oss_presign.go`/`oss_upload.go` ownership hook → `oss_delete.go` → `ai_config.go` → `compose_ai.go`。
3. **go_ai_talk HTTP**：App delete/polish handlers → Admin ai-config handlers → gateway Admin 代理 → 部署 ucg-service + gateway。
4. **go_ai_talk Admin UI**：`ucg-admin.html` + `admin.html` 卡片。
5. **Flutter**：shell sheet → compose refactor → repository delete/polish → 移除 dispose auto-save。
6. **验证**：无草稿 tap+ sheet；有草稿直达；长按 text-only；9 宫格 drag/delete；放弃 orphan 清理；polish 有图；Admin 改模型后 polish 生效；keyboard 失焦不写 SP 回归。
7. **回滚**：Flutter revert compose/shell；backend delete/polish 可保留（无害）；presign 写表可 feature-flag。

## Open Questions

- Polish 结果是 **replace** 还是 **append** 正文？（本设计默认 replace，实现前可产品确认。）
- `POST /posts/polish` vs `/compose/ai-polish` 最终 path？（tasks 阶段与 backend 统一为 `/posts/polish`。）
- Web 是否完全隐藏「拍摄」？（建议 `kIsWeb` 隐藏。）
