## MODIFIED Requirements

### Requirement: go_ai_talk SHALL record ownership in oss_presign and oss_upload

When presign or server-side upload succeeds, `go_ai_talk/internal/services/ucg/` MUST NOT insert `ucg_media_upload` on presign alone. Ownership MUST be recorded only via `POST /media/register` after OSS object exists (miss path) or after resolve hit (dedup path). `UploadMediaObject` Web proxy path MUST follow the same register semantics if used without prior register.

presign 或同域 upload 成功时**不得**仅在 presign 阶段写 `ucg_media_upload`；ownership 须通过 `POST /media/register` 在 OSS 对象就绪（miss）或 resolve hit 后登记。

#### Scenario: presign 不写 ownership
- **WHEN** `PresignUpload` 返回 objectKey 给已登录用户且客户端尚未 register
- **THEN** 服务 SHALL NOT insert `ucg_media_upload`

#### Scenario: register 写 ownership
- **WHEN** 客户端完成 PUT 并调用 `POST /media/register`（`dedupHit: false`）
- **THEN** 服务 SHALL insert `ucg_media_upload` with caller wxId 与 objectKey

#### Scenario: dedup hit register 写 ownership
- **WHEN** 客户端 resolve hit 后调用 register（`dedupHit: true`）
- **THEN** 服务 SHALL insert `ucg_media_upload` for caller wxId
- **AND** SHALL increment `ucg_media_blob.ref_count`

### Requirement: ucg-service SHALL record media ownership on presign upload

The ucg-service MUST record media ownership exclusively through `POST /ucg/app/api/media/register`, not at presign time. Each successful register MUST insert or upsert `ucg_media_upload` with `wx_id`, `object_key`, `media_kind`, and `created_at`. The `object_key` MUST remain unique in the ownership table per wxId scope (upsert per wxId+objectKey).

ucg-service 必须仅经 `POST /media/register` 记录媒体所有权，不得在 presign 时写入。register 成功须 insert/upsert `ucg_media_upload`（wx_id、object_key、media_kind、created_at）。

#### Scenario: register 后写入 ownership
- **WHEN** 已登录用户完成 register（miss 或 hit）
- **THEN** 服务 SHALL 在 `ucg_media_upload` 记录 wxId 与 objectKey

#### Scenario: 重复 register 幂等
- **WHEN** 同一 wxId 对同一 objectKey 再次 register
- **THEN** 服务 SHALL 保持单行 ownership 记录（upsert 或 ignore duplicate）

### Requirement: Media delete SHALL protect published post references

Before deleting OSS, the delete handler MUST query `ucg_post_media` for each objectKey. Keys referenced by any post MUST NOT be deleted from OSS. For non-skipped keys, the handler MUST remove the `ucg_media_upload` row, decrement `ucg_media_blob.ref_count` when a blob row exists, and delete OSS only when `ref_count` reaches zero after decrement.

删除前必须检查 `ucg_post_media`；已发帖引用的 key 不得删除 OSS。对非 skip 的 key，须删除 ownership 行、递减 blob `ref_count`（若存在），且仅当递减后 `ref_count=0` 时删除 OSS。

#### Scenario: 发帖后 delete 跳过
- **WHEN** 用户发布帖子引用了 objectKey 后调用 delete
- **THEN** OSS 对象 SHALL 保留
- **AND** 响应 SHALL 将该 key 标记为 skipped

#### Scenario: 孤儿 delete 递减 ref_count
- **WHEN** 用户 delete 未发帖引用的自有 objectKey 且 blob 存在 ref_count=1
- **THEN** 服务 SHALL 删除 OSS 对象与 blob 行
- **AND** SHALL 删除 `ucg_media_upload` 行

## ADDED Requirements

### Requirement: Legacy ucg_media_upload rows without blob index SHALL remain deletable

Existing `ucg_media_upload` rows created before dedup deployment MAY have no corresponding `ucg_media_blob` row. Delete handler MUST still process ownership and post-reference checks; blob ref_count logic MUST apply only when a blob row exists for the objectKey.

dedup 部署前创建的 `ucg_media_upload` 行可能无对应 blob 记录。delete 仍须处理 ownership 与 post 引用校验；仅当存在 blob 行时才执行 ref_count 递减。

#### Scenario: 无 blob 行的存量 key 删除
- **WHEN** objectKey 存在于 `ucg_media_upload` 但无 `ucg_media_blob` 行且无 post 引用
- **THEN** 服务 SHALL 删除 OSS 对象与 ownership 行
- **AND** SHALL NOT 因缺少 blob 行而失败
