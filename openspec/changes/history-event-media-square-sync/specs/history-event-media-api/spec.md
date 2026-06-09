## ADDED Requirements

### Requirement: History 实体 MUST 暴露 postId 与媒体字段

The go_ai_talk `entity.History` and history list/update API responses SHALL include `postId`, `mediaType`, `imageKeys`, and `videoKey` so clients can render synced media and re-edit linked UCG posts.

go_ai_talk 的 `entity.History` 及历史 list/update API 响应 MUST 包含 `postId`、`mediaType`、`imageKeys`、`videoKey`，供客户端回显已同步媒体并关联 UCG 帖子再编辑。

#### Scenario: list 返回已同步记录

- **WHEN** 客户端请求 `GET /device/history/api/list` 且某行曾同步广场
- **THEN** 响应项 MUST 含非零 `postId`（若已关联）及对应 `imageKeys` 或 `videoKey`

#### Scenario: 无媒体旧记录兼容

- **WHEN** 数据库历史行无媒体且无 `postId`
- **THEN** API MUST 返回 `postId=0`、`mediaType=0`、空 `imageKeys`、空 `videoKey`（或省略字段由客户端按零值处理）

#### Scenario: WebSocket update 携带媒体

- **WHEN** 服务端经历史 WebSocket 推送 `update` 且记录含媒体
- **THEN** payload MUST 含与 list 一致的 `postId` 与媒体字段

### Requirement: event/update MUST 接受 postId 回写

The history event update endpoint SHALL accept optional `postId` in the request body so the client can persist UCG linkage after create/update/delete.

历史 `event/update` 接口 MUST 在请求体中接受可选 `postId`，供客户端在 UCG 发帖/更新/删帖后回写关联。

#### Scenario: 客户端回写 postId

- **WHEN** 客户端 `createPost` 成功获得新帖子 id
- **THEN** 客户端 MAY 在后续 `event/update` 请求中携带 `postId`，服务端 MUST 持久化该关联

#### Scenario: 删帖后回写清零

- **WHEN** 客户端 `deletePost` 成功后更新历史
- **THEN** 客户端 MAY 提交 `postId=0`，服务端 MUST 清除关联
