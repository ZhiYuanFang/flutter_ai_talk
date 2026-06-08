## Why

UCG 媒体上传当前每次 presign 均生成随机 `objectKey` 并全量上传 OSS，同一 prepared 字节流被不同用户或同用户重复选择时无法复用，造成存储与带宽浪费。在 `ucg-moments-compose-redesign` 已落地 ownership 与孤儿删除能力后，引入基于内容哈希的全局 dedup 可在不改变用户可见发布体验的前提下显著降低 OSS 成本，并为后续 transform 版本演进预留空间。

## What Changes

- **客户端哈希**：在 `ucgUploadBytes` 内，于 `ucgCompressImageBytes` / 视频 prepare 之后、上传之前，对 **最终 prepared bytes** 计算 SHA-256，并携带 `transform_version`（首版 `v1`）。
- **同图不同入口不去重（已接受）**：`photo_manager` 与 `image_picker(imageQuality:85)` 等入口若产生不同 prepared bytes，则哈希不同、**不得**跨入口 dedup；产品明确接受此行为。
- **全局 blob 索引**：新增 `ucg_media_blob` 表，映射 `(content_hash, transform_version) → object_key`；`objectKey` 仍采用随机 dated 路径 `social/YYYY/MM/{random32}.ext`（Option A）。
- **上传流程重构**：由 presign-first 写 ownership 改为 **resolve →（命中：登记 ownership、跳过上传 | 未命中：presign + upload → register blob + ownership）**。
- **新 API**：`POST /media/resolve`（查 blob 索引）、`POST /media/register`（上传完成后登记 blob 与 ownership）；presign **不得**在未完成 upload 时写入 ownership。
- **删除语义增强**：`ucg_media_blob` 维护 `ref_count`；delete 时移除 ownership 行、递减 ref_count；仅当 `ref_count=0` 且无 `ucg_post_media` 引用时才删除 OSS 对象。
- **视频**：对 prepared bytes 全文件 SHA-256；承认 `VideoCompress` 非确定性，同源视频可能产生不同哈希。
- **BREAKING（服务端契约）**：presign 成功路径不再自动 insert `ucg_media_upload`；客户端须改走 resolve/register 流程。

## Capabilities

### New Capabilities

- `ucg-media-dedup`：内容哈希计算、`transform_version`、resolve/register 流程、全局 blob 索引与 ref_count 生命周期。

### Modified Capabilities

- `ucg-media-upload`：ownership 写入时机从 presign-first 改为 resolve/register；删除逻辑增加 blob ref_count 与 dedup 命中路径。
- `ucg-api-contract`：新增 `POST /media/resolve`、`POST /media/register` 请求/响应 DTO；调整 presign 与 delete 语义说明。

## Impact

| 仓库 | 路径 | 变更 |
|------|------|------|
| **flutter_ai_talk** | `app/lib/ucg/data/ucg_media_picker.dart` | prepared bytes 后 SHA-256 + transform_version |
| **flutter_ai_talk** | `app/lib/ucg/data/ucg_repository.dart` | resolve → upload/register 编排 |
| **go_ai_talk** | `internal/services/ucg/` | `oss_presign.go`、`oss_upload.go`、`oss_delete.go`；新建 resolve/register 服务 |
| **go_ai_talk** | `internal/controller/`、`api/v1/` | 新 handlers 与路由 |
| **go_ai_talk** | DB migration `ai_voice_ucg` | 新表 `ucg_media_blob`；`hack/config.yaml` + `gf gen dao` |
| **gateway-app** | 白名单 | 注册 resolve/register（须登录 JWT） |

**部署顺序**：先后端 migration + resolve/register API + 调整 presign/delete → 再 Flutter 客户端联调。
