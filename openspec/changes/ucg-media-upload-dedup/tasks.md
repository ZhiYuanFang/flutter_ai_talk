## 1. 后端 go_ai_talk — 数据库与 DAO（ucg-media-dedup）

- [x] 1.1 新增 DDL migration（`ai_voice_ucg`）：`ucg_media_blob`（`content_hash` CHAR(64)、`transform_version` VARCHAR(16)、UNIQUE `(content_hash, transform_version)`、`object_key` UNIQUE、`media_kind`、`ref_count` 默认 0、`created_at`）
- [x] 1.2 `hack/config.yaml` ucg 域 `tables` 追加 `ucg_media_blob`
- [x] 1.3 在 `go_ai_talk` 根目录执行 `gf gen dao`，提交生成物

## 2. 后端 go_ai_talk — resolve/register 服务（ucg-media-dedup / ucg-api-contract）

- [x] 2.1 新建 `internal/services/ucg/media_resolve.go`：`ResolveMediaByHash(ctx, contentHash, transformVersion, mediaKind)` → hit/miss + objectKey/cdnUrl
- [x] 2.2 新建 `internal/services/ucg/media_register.go`：`RegisterMedia(ctx, wxID, req)` — dedupHit=false 时 HEAD/Stat OSS 验证后 insert blob（ref_count=1）+ ownership；dedupHit=true 时 increment ref_count + ownership；事务 + uk_hash_version 并发处理
- [x] 2.3 `internal/controller/ucg_app_api.go` 新增 `MediaResolve`、`MediaRegister` handlers
- [x] 2.4 `api/v1/ucg_app_http.go` 注册 `POST /ucg/app/api/media/resolve` 与 `POST /ucg/app/api/media/register`（OpenAPI struct tags + DTO）
- [x] 2.5 确认 gateway-app **未**将 resolve/register 加入匿名白名单（须 JWT）

## 3. 后端 go_ai_talk — presign 与 delete 调整（ucg-media-upload）

- [x] 3.1 `internal/services/ucg/oss_presign.go`：**移除** `PresignUpload` 成功路径 insert `ucg_media_upload`
- [x] 3.2 `internal/services/ucg/oss_upload.go`：**移除** `UploadMediaObject` 成功路径自动写 ownership（改由 register 负责，或 upload 代理路径文档化）
- [x] 3.3 `internal/services/ucg/oss_delete.go`：`DeleteOwnedMedia` 增强 — 删 ownership 后查 blob 递减 ref_count；ref_count=0 且无 post 引用时删 OSS + blob row；无 blob 行的存量 key 仍按原逻辑删 OSS
- [x] 3.4 联调：resolve hit 多用户共享 blob 时 delete 仅减 ref_count 不删 OSS

## 4. Flutter 数据层 — 哈希与 resolve/register（ucg-media-dedup / ucg-api-contract）

- [x] 4.1 新增 `kUcgMediaTransformVersion = 'v1'` 常量（如 `ucg_media_limits.dart` 或 dedup 专用文件）
- [x] 4.2 `ucg_media_picker.dart`：`ucgUploadBytes` 在 compress/prepare 后对 prepared bytes 计算 SHA-256（`crypto` 包），传入 repository
- [x] 4.3 `ucg_presign.dart`：新增 `UcgResolveResult`、`UcgRegisterRequest` DTO
- [x] 4.4 `UcgRepository.resolveMedia(...)` → `POST /media/resolve`
- [x] 4.5 `UcgRepository.registerMedia(...)` → `POST /media/register`
- [x] 4.6 `UcgRepository.uploadMediaBytes` 重构：resolve →（miss：presign + PUT + register dedupHit=false | hit：register dedupHit=true）

## 5. Flutter 调用方与联调（ucg-media-upload）

- [x] 5.1 确认 `ucg_album_picker.dart`、`ucg_media_picker.dart` 各入口均经 `ucgUploadBytes`，无需单独改 hash 逻辑
- [x] 5.2 compose discard / chip remove 的 `deleteMedia` 路径回归（ref_count 语义）
- [x] 5.3 test 环境联调：相同 prepared bytes 第二用户 resolve hit 跳过 PUT；不同 picker 入口同图不同 hash 各自 upload（验收「同图不同入口不去重」）

## 6. 部署与迁移（design Migration Plan）

- [x] 6.1 同窗口部署 ucg-service migration + API + gateway + Flutter（presign 不写 ownership 为 **BREAKING**）
- [x] 6.2 确认存量 `ucg_media_upload` 无 blob 行时 delete 仍可用（legacy 路径）
- [x] 6.3 文档化 `transform_version` v2 未来 bump 策略（非本迭代实现）
