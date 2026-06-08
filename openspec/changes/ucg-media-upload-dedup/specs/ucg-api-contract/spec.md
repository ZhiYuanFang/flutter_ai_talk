## ADDED Requirements

### Requirement: ucg-service SHALL expose POST /media/resolve for content hash lookup

The ucg-service MUST provide `POST /ucg/app/api/media/resolve` accepting authenticated requests with body `{ "contentHash": string, "transformVersion": string, "mediaKind": int }`. When `(contentHash, transformVersion)` exists in `ucg_media_blob`, response MUST be `{ "hit": true, "objectKey": string, "cdnUrl": string }`. When not found, response MUST be `{ "hit": false }`.

ucg-service 必须提供 `POST /media/resolve`，按 `(contentHash, transformVersion)` 查询 blob 索引；命中返回 objectKey 与 cdnUrl，未命中返回 `hit: false`。

#### Scenario: resolve 命中
- **WHEN** 已登录用户提交已存在 blob 的 contentHash 与 transformVersion
- **THEN** 响应 SHALL 含 `hit: true`、`objectKey`、`cdnUrl`

#### Scenario: resolve 未命中
- **WHEN** contentHash 与 transformVersion 无 blob 记录
- **THEN** 响应 SHALL 含 `hit: false`

#### Scenario: resolve 须登录
- **WHEN** 请求无有效 JWT
- **THEN** gateway/ucg-service SHALL 返回 401

### Requirement: ucg-service SHALL expose POST /media/register for blob and ownership

The ucg-service MUST provide `POST /ucg/app/api/media/register` accepting `{ "objectKey": string, "contentHash": string, "transformVersion": string, "mediaKind": int, "dedupHit": bool }`. For `dedupHit: false`, service MUST verify OSS object exists, insert `ucg_media_blob` with `ref_count=1`, and insert `ucg_media_upload`. For `dedupHit: true`, service MUST verify blob exists, increment `ref_count`, and insert `ucg_media_upload`. Response MUST be `{ "objectKey": string, "cdnUrl": string }`.

ucg-service 必须提供 `POST /media/register`；miss 路径验证 OSS 后建 blob 与 ownership；hit 路径递增 ref_count 并写 ownership。

#### Scenario: register miss 路径
- **WHEN** 客户端提交 `dedupHit: false` 且 OSS 对象已存在
- **THEN** 服务 SHALL insert `ucg_media_blob` 与 `ucg_media_upload`
- **AND** 响应 SHALL 返回 objectKey 与 cdnUrl

#### Scenario: register hit 路径
- **WHEN** 客户端提交 `dedupHit: true` 且 blob 已存在
- **THEN** 服务 SHALL increment `ref_count`
- **AND** SHALL insert `ucg_media_upload` for caller

#### Scenario: register OSS 不存在拒绝
- **WHEN** `dedupHit: false` 且 OSS 无对应 objectKey
- **THEN** 服务 SHALL 返回 400 或 404

### Requirement: UcgRepository SHALL orchestrate resolve register upload flow

`UcgRepository` MUST expose `resolveMedia` and `registerMedia` and MUST update `uploadMediaBytes` to: compute hash (caller-provided or internal), call resolve, on miss call presign + PUT then register with `dedupHit: false`, on hit call register with `dedupHit: true`. Presign alone MUST NOT be treated as upload completion.

`UcgRepository` 必须封装 resolve/register，并更新 `uploadMediaBytes` 为 resolve →（miss：presign + PUT + register | hit：register）；不得将 presign  alone 视为上传完成。

#### Scenario: 客户端 miss 上传编排
- **WHEN** resolve 返回 miss
- **THEN** Client SHALL presign、PUT OSS、register（dedupHit: false）

#### Scenario: 客户端 hit 跳过 PUT
- **WHEN** resolve 返回 hit
- **THEN** Client SHALL register（dedupHit: true）且不得 PUT OSS

## MODIFIED Requirements

### Requirement: ucg-service SHALL expose POST /media/delete for owned orphan objects

The ucg-service MUST provide `POST /ucg/app/api/media/delete` accepting authenticated requests with body `{ "objectKeys": string[] }`. For each key, the service MUST verify ownership via `ucg_media_upload.wx_id == caller wxId`. If the key exists in `ucg_post_media`, the service MUST skip deletion for that key. Otherwise the service MUST remove the `ucg_media_upload` row, decrement `ucg_media_blob.ref_count` when a blob row exists, and delete the OSS object only when post decrement `ref_count` is zero. Response MUST include lists of deleted and skipped keys.

ucg-service 必须提供媒体删除 API；校验所有权；已发帖引用须 skip；否则删除 ownership、递减 blob ref_count（若存在），且仅 ref_count 为 0 时删 OSS。

#### Scenario: 删除自有孤儿对象
- **WHEN** 已登录用户请求删除其拥有且未在 `ucg_post_media` 引用的 objectKey，且 blob ref_count 为 1
- **THEN** 服务 SHALL 删除 OSS 对象与 blob 行
- **AND** 响应 `deleted` SHALL 包含该 key

#### Scenario: 已发帖 media 跳过
- **WHEN** objectKey 已存在于 `ucg_post_media`
- **THEN** 服务 SHALL NOT 删除 OSS
- **AND** 响应 `skipped` SHALL 包含该 key

#### Scenario: 非所有者拒绝
- **WHEN** 用户请求删除他人 upload 记录中的 objectKey
- **THEN** 服务 SHALL NOT 删除
- **AND** 该 key SHALL 出现在 `skipped` 或错误明细中

#### Scenario: 共享 blob 部分 delete
- **WHEN** blob ref_count > 1 且用户 delete 其 ownership
- **THEN** ref_count SHALL 递减
- **AND** OSS SHALL 保留
- **AND** 响应 `deleted` MAY 包含该 key（ownership 已移除）

### Requirement: UcgRepository SHALL call deleteMedia and polishPost

`UcgRepository` / `UcgApiClient` MUST expose `deleteMedia({required List<String> objectKeys})` and `polishPost({required List<String> imageKeys, String? text})` calling the canonical gateway-prefixed endpoints with existing envelope decode. Media upload MUST use resolve/register flow in addition to presign for OSS PUT on miss.

Flutter 仓库层必须封装 delete 与 polish API；媒体上传 miss 路径须经 resolve → presign → register 编排。

#### Scenario: 客户端删除媒体
- **WHEN** compose 移除图片或放弃草稿
- **THEN** Client SHALL 调用 `POST /ucg/app/api/media/delete`

#### Scenario: 客户端润笔
- **WHEN** 用户点击 AI 润笔
- **THEN** Client SHALL 调用 `POST /ucg/app/api/posts/polish`

#### Scenario: 上传经 resolve register
- **WHEN** 客户端上传媒体
- **THEN** Client SHALL 先调用 `POST /ucg/app/api/media/resolve`
- **AND** on miss SHALL 调用 `POST /ucg/app/api/media/presign` 与 PUT
- **AND** SHALL 调用 `POST /ucg/app/api/media/register` 完成上传
