## MODIFIED Requirements

### Requirement: App UCG client SHALL use v1 feed and comment paths

The Flutter `UcgApiClient` repository layer MUST call v1 paths for recommend feed, following feed, post create, and comments. The following v2 paths MUST NOT be used by App after this change: `/ucg/app/api/v2/feed/recommend`, `/ucg/app/api/v2/feed/following`, `/ucg/app/api/v2/posts`, `/ucg/app/api/v2/posts/{id}/comments`.

App MUST 停用 UCG v2 Feed/创建/评论路径。

#### Scenario: 推荐 Feed v1

- **WHEN** App 加载推荐广场
- **THEN** GET MUST target `/ucg/app/api/feed/recommend` without `v2` base
- **AND** MUST NOT expect `comments[]` on items

#### Scenario: 创建帖 v1

- **WHEN** App 发布动态或辩论帖
- **THEN** POST MUST target `/ucg/app/api/posts`
- **AND** MUST NOT call `/ucg/app/api/v2/posts`

## ADDED Requirements

### Requirement: v1 UcgCommentItem SHALL include voteSide fields

OpenAPI/DTO for v1 comments MUST add `voteSide` and `voteSideLabel` optional JSON fields matching debate comment snapshots.

v1 评论 DTO MUST 扩展 voteSide 字段。

#### Scenario: 评论 JSON 含 voteSide

- **WHEN** 服务端返回辩论帖评论
- **THEN** JSON item MAY include `voteSide` and `voteSideLabel`

## REMOVED Requirements

### Requirement: App SHALL consume v2 feed with comment preview

**Reason**: Consolidated to v1 feed without inline comments.

**Migration**: Set `v2: false` on feed fetches; remove `type=debate` default filter.
