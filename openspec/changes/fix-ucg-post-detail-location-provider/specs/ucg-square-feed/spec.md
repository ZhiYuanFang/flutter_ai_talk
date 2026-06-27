## ADDED Requirements

### Requirement: Post detail read SHALL use ucgPostDetailProvider with coordinates when granted

When loading a single post for `UcgPostDetailScreen`, the client MUST fetch the post via `ucgPostDetailProvider(postId)` (or equivalent that calls `readCurrentCoordsIfGranted` and `fetchPost` with optional `lat`/`lng`). The screen MUST NOT call `fetchPost` directly without coordinates. When When-In-Use location is already granted, the detail request MUST include device `lat`/`lng` query parameters. The detail screen MUST NOT invoke the UCG location consent dialog (`ensureUcgLocationForDistance`); denial or missing permission MUST still load the post without coordinates.

帖子详情 MUST 经 `ucgPostDetailProvider` 加载；已授权定位时 MUST 附带 `lat`/`lng`；详情页 MUST NOT 弹定位 consent；无坐标时 MUST 仍可加载详情。

#### Scenario: 已授权用户打开详情

- **WHEN** 用户已授予「使用时定位」并打开 `UcgPostDetailScreen`
- **THEN** Client SHALL 通过 `ucgPostDetailProvider` 调用 `GET /posts/{id}` 且 query 含 `lat` 与 `lng`
- **AND** 响应含 `distanceMeters` 时详情 meta 行 SHALL 展示距离

#### Scenario: 下拉刷新详情

- **WHEN** 用户在详情页触发下拉刷新
- **THEN** App SHALL `invalidate` `ucgPostDetailProvider(postId)` 并重新拉取
- **AND** 已授权时重新请求 MUST 仍附带 `lat`/`lng`

#### Scenario: 未授权定位打开详情

- **WHEN** 用户未授权定位并从任意入口打开详情
- **THEN** App SHALL 经 Provider 以无 `lat`/`lng` 请求 `GET /posts/{id}`
- **AND** 详情 MUST 正常展示（距离 MAY 为空）

#### Scenario: 从 Feed 带 seedPost 进入

- **WHEN** 导航传入 `seedPost` 且 Provider 仍在 loading
- **THEN** 详情 MAY 先展示 `seedPost` 占位
- **AND** Provider 成功后 SHALL 以网络帖子覆盖（含更新后的 `distanceMeters`）
