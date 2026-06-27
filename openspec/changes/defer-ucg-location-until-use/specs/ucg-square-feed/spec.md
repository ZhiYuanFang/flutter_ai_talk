## MODIFIED Requirements

### Requirement: Feed cards SHALL display post IP location snapshot

`UcgPostItem` and feed DTOs SHALL expose `ipLocation` (server snapshot at post creation). Feed cards SHALL render IP location adjacent to post time (e.g. `MM-dd HH:mm · 广东 深圳`); when absent, time alone is sufficient. Client MUST NOT send `ipLocation` in request bodies. For distance display, when the user has granted When-In-Use location, the client MAY send device `lat`/`lng` query parameters on feed and post read APIs; server MAY return `distanceMeters` for masonry/detail display via `distanceDisplay`. When location is unavailable or denied, the client MUST still load feeds without coordinates and MUST omit distance badges.

Feed DTO MUST 暴露服务端 `ipLocation` 快照并展示；客户端 MUST NOT 在请求体发送 `ipLocation`。用户授权「使用时定位」后，客户端 MAY 在 Feed/详情读 API 附带 `lat`/`lng` 以获取 `distanceMeters` 距离展示；无坐标时 MUST 仍可加载 Feed 且不展示距离角标。

#### Scenario: 帖子展示发帖属地

- **WHEN** Feed 项含非空 `ipLocation`
- **THEN** 卡片时间行 SHALL 在日期旁展示属地文案

#### Scenario: 授权后展示距离角标

- **WHEN** Feed 项含非空 `distanceMeters` 且用户已授权定位
- **THEN** masonry 卡片 SHALL 展示格式化的距离角标（如 `500m`、`1.2km`）

#### Scenario: 拒绝定位仍可浏览推荐

- **WHEN** 用户拒绝或未授权定位并打开推荐 Tab
- **THEN** App SHALL 以无 lat/lng 请求 Feed 并展示帖子列表
- **AND** 距离角标 MAY 为空

## ADDED Requirements

### Requirement: Square feed initial load SHALL use UCG location consent

When the square tab performs its first feed refresh (recommended or following), the client MUST invoke the UCG location consent flow before attaching coordinates to the feed request. Denial MUST NOT prevent the feed request.

广场 Tab 首屏或刷新加载 Feed 前 MUST 走 UCG 定位同意流程；拒绝后 MUST 仍发起无坐标 Feed 请求。

#### Scenario: 进广场后首屏拉 Feed

- **WHEN** 用户首次进入 UCG 广场且推荐 Tab 触发 refresh load
- **THEN** App SHALL 先执行 `ensureUcgLocationForDistance`（或等价）
- **AND** 随后 SHALL 调用 `fetchRecommendedFeed`（带或不带 lat/lng）
