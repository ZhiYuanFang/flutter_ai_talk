## MODIFIED Requirements

### Requirement: v1 comment items SHALL expose debate vote side

v1 `UcgCommentItem` MUST include optional `voteSide` (`left`|`right`) and `voteSideLabel` (human-readable stance label snapshot). `GET /ucg/app/api/posts/{id}/comments` and `POST` comment responses MUST populate these fields for debate-post comments. App and mini program MUST call v1 comment endpoints only (`v2: false` / no `/api/v2/` prefix).

v1 评论 MUST 返回 voteSide；客户端 MUST 停用 v2 评论 API。

#### Scenario: 拉取辩论论点含立场

- **WHEN** App 请求 v1 评论列表且帖为辩论帖
- **THEN** 每条已发布评论 MAY 含 `voteSide` 与 `voteSideLabel`
- **AND** App SHALL 解析并展示立场标签

#### Scenario: App 不使用 v2 评论路径

- **WHEN** App 调用 `fetchComments` 或 `addComment`
- **THEN** HTTP path MUST be `/ucg/app/api/posts/{id}/comments`
- **AND** MUST NOT use `/ucg/app/api/v2/posts/{id}/comments`

### Requirement: Debate arguments SHALL load only after viewer voted

For debate posts on 广场 feed cards and detail, the client MUST NOT fetch or display the full comment list until `myVoteSide` is non-empty (except detail author moderation paths unchanged). Feed API MUST NOT supply comment preview arrays.

辩论评论列表 MUST 在投票后才加载；Feed MUST NOT 带评论预览。

#### Scenario: 详情页未投票不拉评论

- **WHEN** 用户打开辩论帖详情且未投票
- **THEN** App SHALL NOT 展示论点列表
- **AND** MAY 展示 VS 条引导投票

#### Scenario: 投票后拉评论

- **WHEN** 用户完成投票
- **THEN** App SHALL 调用 v1 评论 GET 并渲染论点

## REMOVED Requirements

### Requirement: Feed v2 SHALL embed comments preview

**Reason**: Product returns to v1 feed without inline comments; lazy load after vote.

**Migration**: Remove v2 feed client usage; remove server `enrichPostsWithCommentsPreview` on feed assembly.
