## 1. 后端 go_ai_talk — 数据库与 DAO（ucg-media-upload / ucg-ai-config）

- [x] 1.1 新增 DDL migration（`ai_voice_ucg`）：`ucg_media_upload`（`wx_id` 索引、`object_key` UNIQUE、`media_kind`、`created_at`）
- [x] 1.2 新增 DDL migration：`ucg_ai_config` 单例行 id=1（`vision_model`、`max_images_per_request`、`updated_at`、`updated_by`）+ seed 默认值
- [x] 1.3 `hack/config.yaml` ucg 域 `tables` 追加 `ucg_media_upload, ucg_ai_config`
- [x] 1.4 在 `go_ai_talk` 根目录执行 `gf gen dao`，提交 `internal/dao/`、`internal/model/entity/`、`internal/model/do/` 生成物

## 2. 后端 go_ai_talk — 媒体 ownership 与 OSS 删除（ucg-media-upload）

- [x] 2.1 `internal/services/ucg/oss_presign.go`：`PresignUpload` 成功后 insert `ucg_media_upload`（wxId + objectKey + mediaKind）
- [x] 2.2 `internal/services/ucg/oss_upload.go`：`UploadMediaObject` 成功后同样写 ownership row（Web 同域代理路径）
- [x] 2.3 新建 `internal/services/ucg/oss_delete.go`：`DeleteOwnedMedia(ctx, wxID, objectKeys)` — 所有权校验 → 查 `ucg_post_media` skip → OSS DeleteObject → 删 upload row
- [x] 2.4 `internal/controller/ucg_app_api.go` 新增 `MediaDelete` handler
- [x] 2.5 `api/v1/ucg_app_http.go` 注册 `POST /ucg/app/api/media/delete`（body `{ objectKeys }`，响应 `{ deleted, skipped }`）
- [x] 2.6 确认 `gateway_app_auth_exempt.go` **未**将 `/media/delete` 加入匿名白名单（须登录 JWT）

## 3. 后端 go_ai_talk — AI 配置与润笔（ucg-ai-config / ucg-compose-ai-polish）

- [x] 3.1 `manifest/config/config.ucg-service.yaml` 增加 `ucg.ai` block（`dashscope_api_key`、`vision_endpoint`、`default_vision_model`、`default_max_images_per_request`）；凭证仅 yaml 配置
- [x] 3.2 新建 `internal/services/ucg/ai_config.go`：`LoadAIConfig`（DB id=1 + YAML fallback）、~60s TTL 内存缓存、`InvalidateAIConfigCache`
- [x] 3.3 新建 `internal/services/ucg/compose_ai.go`：`PolishPostText` — imageKeys → `BuildCdnURL` → DashScope Qwen vision HTTP（OpenAI 兼容 multimodal；先图后文）
- [x] 3.6 切换默认 vision 模型为 `deepseek-ai/deepseek-vl2`；endpoint 默认 SiliconFlow；allowlist 移除 `deepseek-chat`；已有 DB 执行 VL2 migration UPDATE
- [x] 3.7 切换 AI 润笔至 DashScope Qwen vision：`qwen3-vl-plus`、endpoint `dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`；yaml `dashscope_api_key`/`vision_endpoint`；messages 先图后文、无 system role；默认 prompt「作为宝宝家长…」
- [x] 3.4 `internal/controller/ucg_app_api.go` 新增 `PostsPolish` handler
- [x] 3.5 `api/v1/ucg_app_http.go` 注册 `POST /ucg/app/api/posts/polish`（body `{ imageKeys, text? }`，响应 `{ polishedText }`；缺 key 503；超限 400）

## 4. 后端 go_ai_talk — Admin API 与 UI（ucg-ai-config）

- [x] 4.1 新建 `internal/controller/ucg_admin_api.go`：`AiConfigGet` / `AiConfigPut`（Header `X-Admin-Password`；yaml `ucg.admin.password`）
- [x] 4.2 新建 `api/v1/ucg_admin_http.go`：`GET/PUT /ucg/admin/api/ai-config`；PUT 校验 `visionModel` 硬编码 allowlist
- [x] 4.3 `internal/controller/register_ucg_service.go`：`group.Bind(NewUcgAdminCtrl())` 注册 Admin 路由
- [x] 4.4 `resource/public/admin.html` 增加 UCG 卡片 → 链接 `ucg-admin.html`
- [x] 4.5 新建 `resource/public/ucg-admin.html`：模型下拉（allowlist）、maxImagesPerRequest 表单、保存调用 PUT
- [x] 5.1 gateway-app：增加 `/ucg/admin/api/*` 反向代理至 ucg-service（对齐 `ucg_route_proxy.go` `/ucg/app/api/*` 模式）
- [ ] 5.2 test 环境部署 ucg-service + gateway；验证 presign 写 `ucg_media_upload`、delete/polish 需 JWT、Admin ai-config 需口令
- [x] 5.3 在 `config.ucg-service.yaml` 配置 `ucg.ai.dashscope_api_key` 与 `ucg.admin.password`（yaml-only，不用 .env）

## 6. Flutter 数据层（ucg-api-contract / ucg-media-upload）

- [x] 6.1 `UcgRepository.deleteMedia(objectKeys)` → `POST /ucg/app/api/media/delete`
- [x] 6.2 `UcgRepository.polishPost(imageKeys, text?)` → `POST /ucg/app/api/posts/polish`
- [x] 6.3 Compose session 跟踪 `_sessionUploadedKeys`；remove/discard 时批量 delete

## 7. Flutter 入口与 Sheet（ucg-shell-navigation）

- [x] 7.1 `UcgShell`：短按「+」检测 `UcgComposeDraftStore` 是否有非空草稿
- [x] 7.2 无草稿：展示 `UcgComposeEntrySheet`（拍摄 | 从手机相册选择）
- [x] 7.3 有草稿：跳过 sheet，`Navigator.push` compose 并 restore
- [x] 7.4 长按「+」：`UcgComposeScreen(textOnly: true)`，隐藏新媒体 picker
- [x] 7.5 实现拍摄/相册编排：`ucg_media_picker` 扩展 camera source；上传完成后带 `initialImageKeys` / `initialVideoKey` 进入 compose
- [x] 7.6 Web：`kIsWeb` 隐藏或禁用「拍摄」— `ucg-shell-navigation`

## 8. Flutter Compose 页重构（ucg-compose-post）

- [x] 8.1 移除标题字段；仅保留 `ManagedKeyboardTextField` 正文（scene `ucg.compose.body` 不变）
- [x] 8.2 实现 3×3 九宫格媒体区（图片预览 + 视频单格）
- [x] 8.3 图片 drag-reorder；底部 `UcgComposeDeleteZone` drag-to-delete
- [x] 8.4 页内「添加图片」仅图片模式且 <9；互斥视频；视频模式不可替换
- [x] 8.5 `PopScope` + close：`空内容直退` / `有内容三选项对话框`（保存草稿 / 放弃 / 取消）
- [x] 8.6 **移除** `dispose()` 中 `_persistDraft()`；放弃路径 clear draft + delete orphans
- [x] 8.7 确认 keyboard tension：失焦 soft-sync 不写 SP；确认条「确定」与「保存草稿」仍写 SP — 对齐 `ucg-keyboard-input-enhancements`
- [x] 8.8 text-only 模式：隐藏添加媒体 UI；草稿媒体只读展示 + remove（remove 调 delete）

## 9. Flutter AI 润笔（ucg-compose-ai-polish）

- [x] 9.1 compose 页增加「AI润笔」按钮；`visible = imageKeys.isNotEmpty && videoKey == null`
- [x] 9.2 点击调用 `polishPost`；loading 态；成功 replace 正文；失败 snackbar

## 10. 联调与验收

- [ ] 10.1 后端：presign → `ucg_media_upload` 有 row；delete 删 OSS；已发帖 key 在 skipped；polish 返回 polishedText
- [ ] 10.2 后端：Admin PUT ai-config → polish 使用新 model；非法 model 400
- [ ] 10.3 Flutter：无草稿 tap+ sheet → 相册/拍摄 → compose 预填
- [ ] 10.4 Flutter：有草稿 tap+ 直达 restore；长按 text-only
- [ ] 10.5 Flutter：9 宫格排序、拖删、页内加图、视频不可换
- [ ] 10.6 Flutter：关闭三选项；放弃 OSS delete；发布成功不 delete
- [ ] 10.7 Flutter：有图 AI 润笔；无图/视频隐藏按钮
- [ ] 10.8 回归：compose 键盘 emoji/失焦不写 SP/确定写 SP
- [x] 10.9 运行 `openspec validate ucg-moments-compose-redesign`（若 CLI 支持）
