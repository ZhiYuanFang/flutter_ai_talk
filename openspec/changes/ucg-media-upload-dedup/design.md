## Context

UCG 媒体上传链路（Flutter `app/lib/ucg/data/`）当前流程：

```text
ucgUploadBytes → ucgCompressImageBytes / ucgPrepareVideoBytes
              → UcgRepository.uploadMediaBytes
              → presignMedia (POST /media/presign)
              → PUT OSS
              → presign 成功时服务端 insert ucg_media_upload
```

`objectKey` 由服务端 `buildObjectKey` 生成随机 dated 路径 `social/YYYY/MM/{random32}.ext`，每次上传均为新 key，无内容级 dedup。

`ucg-moments-compose-redesign` 已引入 `ucg_media_upload` ownership 表与 `POST /media/delete` 孤儿清理。本次在 prepared bytes 层引入 SHA-256 全局 dedup，跨用户复用 OSS 对象，同时保留随机 objectKey 与现有 CDN URL 形态。

**范围**：`d:\work\flutter_ai_talk\app\lib\ucg\` + `d:\work\go_ai_talk` ucg-service + gateway-app。

**已接受产品决策**：同一张相册原图经 `photo_manager` 与 `image_picker(imageQuality:85)` 等不同入口 pick 时，若 prepared bytes 不同，则哈希不同、**不得**跨入口 dedup（「同图不同入口不去重」）。

## Goals / Non-Goals

**Goals:**

- 对 **最终 prepared bytes**（Option B）计算 SHA-256，携带 `transform_version`（首版 `v1`）。
- 全局 `ucg_media_blob` 索引：`(content_hash, transform_version) → object_key`，`ref_count` 追踪引用。
- 上传流程：**resolve →（hit: register ownership, skip upload | miss: presign + upload → register blob + ownership）**。
- 新 API：`POST /media/resolve`、`POST /media/register`；presign **不得**在未完成 upload 时写 ownership。
- delete：移除 ownership 行、递减 blob `ref_count`；仅 `ref_count=0` 且无 `ucg_post_media` 引用时删 OSS。
- Flutter 与 go_ai_talk 同步落地；gateway 注册新路由（须 JWT）。

**Non-Goals:**

- 跨 `transform_version` dedup（v2 压缩算法变更视为新内容）。
- 原始文件级哈希（pick 前 bytes）或感知哈希（pHash）。
- 跨入口归一化（强制统一 picker 路径以 dedup 同图）。
- Web 端 VideoCompress 完整 parity 或视频压缩确定性保证。
- 自动化测试文件（按仓库规则）。

## Decisions

### 1. 哈希：prepared bytes SHA-256 + transform_version

| 字段 | 值 |
|------|-----|
| 算法 | SHA-256（hex lowercase，64 字符） |
| 输入 | `ucgUploadBytes` 内 compress/prepare **之后**的 `Uint8List` |
| transform_version | 字符串，首版 `"v1"`（图片=当前 `ucgCompressImageBytes`；视频=当前 `ucgPrepareVideoBytes`） |
| 位置 | Flutter `ucg_media_picker.dart` `ucgUploadBytes`，传至 repository |

**备选**：原始 bytes 哈希 — 拒绝，无法反映实际上传内容。

**备选**：MD5 — 拒绝，碰撞风险与行业惯例。

### 2. 同图不同入口不去重（已接受）

`photo_manager` 直读原图与 `image_picker(imageQuality:85)` 解码再压缩产生不同 prepared bytes → 不同 hash → 各自 upload。产品明确接受，不在客户端做入口归一化。

### 3. objectKey：Option A — 随机 dated key + blob 索引

- 新 upload miss 时仍生成 `social/YYYY/MM/{random32}.ext`。
- `ucg_media_blob` 存 `(content_hash, transform_version)` UNIQUE → `object_key`、`media_kind`、`ref_count`、`created_at`。
- resolve hit 返回已有 `objectKey` + `cdnUrl`，客户端跳过 PUT。

**备选**：content-addressable key（hash 作路径）— 拒绝，与现有 CDN/运维习惯及 random key 防枚举策略不一致。

### 4. 上传状态机

```text
Client: prepared bytes + SHA-256 + transform_version
    │
    ▼
POST /media/resolve { contentHash, transformVersion, mediaKind }
    │
    ├── hit (blob exists)
    │     └── POST /media/register { objectKey, contentHash, transformVersion, mediaKind, dedupHit: true }
    │           → insert ucg_media_upload (wxId)
    │           → increment ucg_media_blob.ref_count
    │           → return { objectKey, cdnUrl }
    │
    └── miss
          └── POST /media/presign { fileName, mediaKind }  // 不写 ownership
                └── PUT OSS
                      └── POST /media/register { objectKey, contentHash, transformVersion, mediaKind, dedupHit: false }
                            → insert ucg_media_blob (ref_count=1)
                            → insert ucg_media_upload
                            → return { objectKey, cdnUrl }
```

**presign 变更**：`PresignUpload` / `UploadMediaObject` **移除** presign 成功即写 `ucg_media_upload`；ownership 仅经 `register` 写入。

**register 幂等**：同一 `(wxId, objectKey)` upsert；同一 blob 多次 register（dedup hit）递增 `ref_count` 且须存在 ownership row per wxId。

### 5. 数据库：`ucg_media_blob`

```sql
CREATE TABLE ucg_media_blob (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  content_hash CHAR(64) NOT NULL,
  transform_version VARCHAR(16) NOT NULL DEFAULT 'v1',
  object_key VARCHAR(512) NOT NULL UNIQUE,
  media_kind TINYINT NOT NULL,  -- 1=image, 2=video
  ref_count INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uk_hash_version (content_hash, transform_version)
);
```

`hack/config.yaml` 注册 → `gf gen dao`。

### 6. API 契约摘要

**POST /ucg/app/api/media/resolve**

Request: `{ "contentHash": string, "transformVersion": string, "mediaKind": int }`

Response hit: `{ "hit": true, "objectKey": string, "cdnUrl": string }`

Response miss: `{ "hit": false }`

**POST /ucg/app/api/media/register**

Request: `{ "objectKey": string, "contentHash": string, "transformVersion": string, "mediaKind": int, "dedupHit": bool }`

Response: `{ "objectKey": string, "cdnUrl": string }`

- `dedupHit=true`：blob 须已存在；仅增 ref_count + ownership。
- `dedupHit=false`：blob 须不存在；验证 OSS 对象存在后 insert blob + ownership。

**POST /ucg/app/api/media/presign** — 行为不变（返回 uploadUrl/objectKey），**不再**写 ownership。

**POST /ucg/app/api/media/delete** — 增强：

1. 校验 `ucg_media_upload.wx_id == caller`
2. 若 key 在 `ucg_post_media` → skip（不变）
3. 删除 `ucg_media_upload` row
4. 查 `ucg_media_blob` by object_key → `ref_count--`
5. 若 `ref_count==0` 且无 post 引用 → OSS DeleteObject + 删 blob row

### 7. 视频非确定性

`VideoCompress` / `ucgPrepareVideoBytes` 输出可能非 bitwise 稳定。规格明确：每次 prepare 可能产生不同 hash，dedup 仅对 **相同 prepared bytes** 生效；不尝试 normalize 视频编码参数。

### 8. Flutter 改动点

| 文件 | 变更 |
|------|------|
| `ucg_media_picker.dart` | `ucgUploadBytes` 内 SHA-256 + 传 hash/version |
| `ucg_repository.dart` | `resolveMedia` / `registerMedia`；`uploadMediaBytes` 编排 resolve→presign→register |
| `ucg_presign.dart` | 新增 resolve/register DTO |
| 调用方 | `ucg_album_picker.dart` 等经 `ucgUploadBytes` 自动受益 |

常量：`const kUcgMediaTransformVersion = 'v1';`（单处定义，便于 v2 迁移）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| presign 不再写 ownership，旧客户端仍依赖 presign 写 row | **BREAKING**：须 Flutter 与后端同步部署；无并存期 |
| dedup hit 后用户 A delete 导致 ref_count 误减 | delete 仅减 ref_count；ref_count>0 或 post 引用时保留 OSS |
| 并发 miss 双写同一 hash | DB `uk_hash_version` UNIQUE + register 事务；后者 treat duplicate 为 hit |
| 视频非确定性导致 dedup 收益低 | 接受；文档化；未来可 bump transform_version |
| register 伪造 hash 指向他人 blob | register 须 JWT；dedupHit=false 时服务端 HEAD OSS 验证 object 存在 |
| 跨用户 dedup 隐私顾虑 | 仅复用 OSS 字节；ownership 仍 per-wxId；无跨用户 metadata 泄露 |

## Migration Plan

1. **后端**：migration 建 `ucg_media_blob` → gen dao → 实现 resolve/register handlers → 修改 presign/delete 服务 → gateway 路由。
2. **Flutter**：实现 hash + resolve/register 编排 → 联调 test 环境。
3. **部署**：同窗口发布 ucg-service + gateway + Flutter（presign 行为 breaking）。
4. **存量数据**：既有 `ucg_media_upload` 行无 blob 索引；**不**回填 hash（仅新 upload 走 dedup）。存量 object 删除逻辑仍按 post 引用 + ownership，无 ref_count 时 skip blob 递减。
5. **回滚**：回滚 Flutter 至 presign 直传；回滚后端恢复 presign 写 ownership（需保留 register 路由或忽略）。

## Open Questions

- 无（探索阶段决策已闭合：`transform_version` 首版 v1、objectKey Option A、同图不同入口不去重已接受）。

## transform_version v2 迁移策略（非本迭代实现）

当图片压缩（`ucgCompressImageBytes`）或视频 prepare（`ucgPrepareVideoBytes`）算法变更导致 prepared bytes 语义变化时：

1. 在 Flutter 将 `kUcgMediaTransformVersion` bump 为 `"v2"`（单处常量）。
2. **不**迁移或合并 v1 blob 行；v1 与 v2 各自独立 dedup 空间（`uk_hash_version` 含 version 维度）。
3. 存量 v1 blob 与 ownership 继续按 ref_count 生命周期运行直至自然归零。
4. 新 upload 仅写入 v2 索引；resolve miss 路径与 v1 相同。
5. 回滚客户端时须同步回退 `kUcgMediaTransformVersion`，否则 hash 与 server 索引不一致。
