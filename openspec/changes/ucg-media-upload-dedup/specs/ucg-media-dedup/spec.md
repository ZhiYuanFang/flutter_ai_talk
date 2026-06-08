## ADDED Requirements

### Requirement: Client SHALL hash final prepared media bytes before upload

The Flutter client MUST compute SHA-256 (hex lowercase, 64 characters) on the final prepared bytes immediately after `ucgCompressImageBytes` or video prepare and before any upload or resolve call. The client MUST attach `transform_version` (initial value `"v1"`) with every resolve and register request.

客户端必须在图片压缩或视频 prepare 完成后、上传或 resolve 之前，对最终 prepared bytes 计算 SHA-256（hex 小写 64 位），并在 resolve/register 请求中携带 `transform_version`（首版 `"v1"`）。

#### Scenario: 图片上传前哈希
- **WHEN** 用户经任意图片入口完成 pick 且 `ucgUploadBytes` 已执行 `ucgCompressImageBytes`
- **THEN** Client SHALL 对压缩后 bytes 计算 SHA-256
- **AND** SHALL 以 `transform_version` `"v1"` 调用 resolve

#### Scenario: 视频上传前哈希
- **WHEN** 用户选择视频且 `ucgPrepareVideoBytes` 已完成
- **THEN** Client SHALL 对 prepared video bytes 计算 SHA-256
- **AND** SHALL 以 `transform_version` `"v1"` 调用 resolve

### Requirement: Different picker entry points with different prepared bytes SHALL NOT deduplicate

When the same gallery photo is picked via different client entry points (e.g. `photo_manager` vs `image_picker` with `imageQuality: 85`) and the resulting prepared bytes differ, the system MUST treat them as distinct content hashes and MUST NOT deduplicate across those uploads.

当同一相册原图经不同 picker 入口（如 `photo_manager` 与 `image_picker(imageQuality:85)`）产生不同 prepared bytes 时，系统必须视为不同 content hash，不得跨入口 dedup。

#### Scenario: photo_manager 与 image_picker 产生不同 bytes
- **WHEN** 用户 A 经 `photo_manager` 上传某图得到 hash H1
- **AND** 用户 B 经 `image_picker(imageQuality:85)` 上传同一原图得到不同 prepared bytes 与 hash H2
- **THEN** 系统 SHALL 将 H1 与 H2 视为不同 blob
- **AND** SHALL 执行两次独立 OSS 存储（若均为 miss）

#### Scenario: 相同 prepared bytes 跨用户 dedup
- **WHEN** 两名用户上传产生 bitwise 相同的 prepared bytes 与相同 `transform_version`
- **THEN** resolve SHALL 对第二名用户返回 hit
- **AND** 第二名用户 SHALL NOT 再次 PUT OSS

### Requirement: ucg_media_blob table SHALL index content hash to object key

Database migration in `go_ai_talk` MUST create `ucg_media_blob` in `ai_voice_ucg` with at minimum: primary key, `content_hash` (CHAR 64), `transform_version` (VARCHAR), UNIQUE `(content_hash, transform_version)`, `object_key` (UNIQUE), `media_kind` (1=image, 2=video), `ref_count` (INT, default 0), `created_at`. Table MUST be registered in `hack/config.yaml` before `gf gen dao`.

须在 `ai_voice_ucg` 创建 `ucg_media_blob` 表，以 `(content_hash, transform_version)` 唯一索引映射至 `object_key`，并维护 `ref_count`。

#### Scenario: migration 创建 blob 表
- **WHEN** 部署 ucg-service migration
- **THEN** 数据库 SHALL 存在 `ucg_media_blob` 及 `(content_hash, transform_version)` 唯一约束

#### Scenario: resolve hit 查表
- **WHEN** `POST /media/resolve` 收到已存在的 `(contentHash, transformVersion)`
- **THEN** 服务 SHALL 返回对应 `objectKey` 与 `cdnUrl`
- **AND** 响应 `hit` SHALL 为 true

### Requirement: Upload flow SHALL resolve before upload and register after ownership

The client and ucg-service MUST implement resolve-then-upload: on resolve miss, presign and PUT OSS, then register blob and ownership; on resolve hit, register ownership and increment ref_count without PUT. Presign MUST NOT insert `ucg_media_upload` until register completes.

上传流程必须为 resolve →（hit：register ownership、跳过 PUT | miss：presign + PUT → register blob 与 ownership）。presign 成功不得在未完成 upload 时写入 ownership。

#### Scenario: resolve miss 完整上传
- **WHEN** resolve 返回 `hit: false`
- **THEN** Client SHALL 调用 presign、PUT OSS、再调用 register（`dedupHit: false`）
- **AND** 服务 SHALL insert `ucg_media_blob`（`ref_count=1`）与 `ucg_media_upload`

#### Scenario: resolve hit 跳过上传
- **WHEN** resolve 返回 `hit: true` 含 `objectKey`
- **THEN** Client SHALL NOT PUT OSS
- **AND** SHALL 调用 register（`dedupHit: true`）
- **AND** 服务 SHALL increment `ucg_media_blob.ref_count` 并 insert `ucg_media_upload`

#### Scenario: presign 不写 ownership
- **WHEN** `PresignUpload` 返回 objectKey 且客户端尚未完成 PUT 与 register
- **THEN** 服务 SHALL NOT insert `ucg_media_upload`

### Requirement: Blob ref_count SHALL gate OSS deletion

When deleting owned media, the service MUST decrement `ucg_media_blob.ref_count` for the object key after removing the ownership row. OSS DeleteObject MUST occur only when `ref_count` reaches zero AND the key is not referenced in `ucg_post_media`.

删除 owned media 时须在移除 ownership 行后递减 blob `ref_count`；仅当 `ref_count` 为 0 且无 `ucg_post_media` 引用时才删除 OSS 对象。

#### Scenario: 多用户共享 blob 部分 delete
- **WHEN** blob `ref_count=2` 且用户 A 删除其 ownership 行
- **THEN** `ref_count` SHALL 变为 1
- **AND** OSS 对象 SHALL 保留

#### Scenario: 最后一引用 delete
- **WHEN** blob `ref_count=1` 且无 `ucg_post_media` 引用且用户删除 ownership
- **THEN** 服务 SHALL 删除 OSS 对象
- **AND** SHALL 删除 `ucg_media_blob` 行

#### Scenario: 已发帖引用仍跳过 OSS 删除
- **WHEN** objectKey 存在于 `ucg_post_media`
- **THEN** 服务 SHALL NOT 删除 OSS
- **AND** 该 key SHALL 出现在 delete 响应 `skipped` 中
