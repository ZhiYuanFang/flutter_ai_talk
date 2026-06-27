## MODIFIED Requirements

### Requirement: 同步开启保存 MUST 发布或更新 UCG 帖子

When sync is ON and JWT `sub` is non-zero, save MUST compress media to UCG limits, upload via presign pipeline, invoke the UCG location consent flow, and call `createPost` (no `postId`) or `updatePost` (existing `postId`) with a formatted post caption: line 1 `{babyName}的{eventName}`, line 2 the remark when non-empty (joined by `\n`). Baby name MUST come from settings baby profile nickname; event name MUST prefer event catalog lookup by `eventId`, else `HistoryRecord.eventName`, with empty resolving to `未知事件`. When baby nickname is missing or placeholder (`未绑定宝宝ID` / `待设置`), line 1 MUST use `宝宝` as `{babyName}`. Returned coordinates when granted MUST be passed as lat/lng on create/update; denial MUST NOT block sync publish.

当「同步广场」开启且 JWT `sub≠0` 时，保存 MUST 压缩上传媒体、走 UCG 定位同意流程，并调用 `createPost`/`updatePost`；caption 格式不变；有坐标则传入 lat/lng；拒绝定位 MUST NOT 阻断同步发帖/更新。

#### Scenario: 首次同步发帖

- **WHEN** 用户保存且同步开启、`postId` 为空、已选媒体且 `sub≠0`
- **THEN** 客户端 MUST 上传媒体、执行定位同意、调用 `createPost`，成功后 MUST 将返回的 `postId` 合并进本地历史记录

#### Scenario: 再次编辑已同步记录

- **WHEN** 用户保存且同步开启、记录含非空 `postId`、已调整媒体或备注
- **THEN** 客户端 MUST 执行定位同意并调用 `updatePost` 更新对应帖子

#### Scenario: 同步 caption 含宝宝与事件名

- **WHEN** 用户保存且同步开启、宝宝 nickname 为「小明」、事件名为「喂奶」、备注为「120ml」
- **THEN** `createPost` / `updatePost` 的 `text` MUST 为 `小明的喂奶\n120ml`（第一行 `{宝宝名}的{事件名}`，第二行备注）

#### Scenario: 无备注时 caption 仅一行

- **WHEN** 用户保存且同步开启、备注为空
- **THEN** 帖子 `text` MUST 仅为 `{宝宝名}的{事件名}` 一行，且 MUST NOT 追加空第二行

#### Scenario: sub 为零不得调用 UCG API

- **WHEN** 用户保存且同步开启但 JWT `sub=0`
- **THEN** 客户端 MUST 展示绑定微信提示，且 MUST NOT 调用 `createPost` / `updatePost` / `deletePost`

#### Scenario: 不得以 unionid 拦截

- **WHEN** 用户 `sub≠0` 但未绑定 WeChat unionid
- **THEN** 客户端 MUST 允许 UCG 同步流程，且 MUST NOT 因 unionid / `isWxBound` 单独拦截

#### Scenario: 拒绝定位仍完成同步

- **WHEN** 用户开启同步保存且在定位同意流程中拒绝
- **THEN** 客户端 MUST 仍调用 `createPost` 或 `updatePost`（无 lat/lng）
- **AND** 历史保存与 `postId` 回写 MUST 照常完成
