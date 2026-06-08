## ADDED Requirements

### Requirement: go_ai_talk SHALL record ownership in oss_presign and oss_upload

When presign or server-side upload succeeds, `go_ai_talk/internal/services/ucg/oss_presign.go` (`PresignUpload`) and `oss_upload.go` (`UploadMediaObject`) MUST insert a row into `ucg_media_upload`. DAO access MUST use generated code from `gf gen dao` after registering tables in `hack/config.yaml`.

presign 与同域 upload 成功路径须在 go_ai_talk ucg-service 写 `ucg_media_upload`；DAO 由 gen dao 生成。

#### Scenario: presign 写 ownership
- **WHEN** `PresignUpload` 返回 objectKey 给已登录用户
- **THEN** 服务 SHALL insert `ucg_media_upload` with caller wxId

#### Scenario: Web 代理 upload 写 ownership
- **WHEN** `UploadMediaObject` 完成 OSS PutObject
- **THEN** 服务 SHALL insert 同等 ownership row

### Requirement: ucg-service SHALL record media ownership on presign upload

When `POST /ucg/app/api/media/presign` succeeds and client completes upload, the ucg-service MUST insert or upsert a row in `ucg_media_upload` with `wx_id`, `object_key`, `media_kind`, and `created_at`. The `object_key` MUST be unique in the table.

presign/上传成功路径必须写入 `ucg_media_upload` 所有权记录；object_key 须唯一。

#### Scenario: 上传后写入 ownership
- **WHEN** 已登录用户完成 presign 并获得 objectKey
- **THEN** 服务 SHALL 在 `ucg_media_upload` 记录 wxId 与 objectKey

#### Scenario: 重复 key 幂等
- **WHEN** 同一 objectKey 再次登记且 wxId 相同
- **THEN** 服务 SHALL 保持单行记录（upsert 或 ignore duplicate）

### Requirement: Media delete SHALL protect published post references

Before deleting OSS, the delete handler MUST query `ucg_post_media` for each objectKey. Keys referenced by any post MUST NOT be deleted from OSS or upload log removal MUST be skipped while leaving post media intact.

删除前必须检查 `ucg_post_media`；已发帖引用的 key 不得删除 OSS。

#### Scenario: 发帖后 delete 跳过
- **WHEN** 用户发布帖子引用了 objectKey 后调用 delete
- **THEN** OSS 对象 SHALL 保留
- **AND** 响应 SHALL 将该 key 标记为 skipped

### Requirement: Client SHALL delete orphan media on chip remove and compose discard

The Flutter client MUST call `deleteMedia` when user removes a media chip from compose grid, when user chooses「放弃」on compose exit, and when clearing session uploads that were never published. Client MUST track session-uploaded keys to batch delete on discard.

客户端须在移除 chip、放弃 compose 时调用 delete；须跟踪会话 upload keys。

#### Scenario: 移除 chip 触发 delete
- **WHEN** 用户在 compose 9 宫格移除一张已上传图片
- **THEN** Client SHALL 调用 media delete API 传入该 objectKey

#### Scenario: 放弃 compose 批量 delete
- **WHEN** 用户选择「放弃」且会话中存在已上传未发布的 objectKeys
- **THEN** Client SHALL 批量调用 media delete API

#### Scenario: 发布成功不 delete 已用 keys
- **WHEN** 用户成功发布帖子
- **THEN** Client SHALL NOT 对帖内 objectKeys 调用 delete

### Requirement: ucg_media_upload table SHALL be created in ai_voice_ucg via migration

Database migration in `go_ai_talk` MUST create `ucg_media_upload` in database `ai_voice_ucg` with at minimum: primary key, `wx_id` (indexed), `object_key` (unique), `media_kind` (1=image, 2=video), `created_at`. Table MUST be registered in `hack/config.yaml` ucg domain tables list before `gf gen dao`.

须在 go_ai_talk `ai_voice_ucg` 库创建表并在 hack/config.yaml 注册后 gen dao。

#### Scenario: migration 创建表
- **WHEN** 部署 ucg-service migration
- **THEN** 数据库 SHALL 存在 `ucg_media_upload` 表及 wx_id、object_key 索引

### Requirement: ucg_media_upload table SHALL store upload audit fields

Database migration MUST create `ucg_media_upload` with at minimum: primary key, `wx_id` (indexed), `object_key` (unique), `media_kind` (1=image, 2=video), `created_at`.

数据库须创建 `ucg_media_upload` 表及必要索引。

#### Scenario: migration 创建表
- **WHEN** 部署 ucg-service migration
- **THEN** 数据库 SHALL 存在 `ucg_media_upload` 表及 wx_id、object_key 索引
