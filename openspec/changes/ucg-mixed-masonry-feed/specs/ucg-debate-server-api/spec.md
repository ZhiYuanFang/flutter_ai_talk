## MODIFIED Requirements

### Requirement: Feed assembly SHALL not enrich comment preview

`ListRecommendFeed` and `ListFollowingFeed` MUST NOT call `enrichPostsWithCommentsPreview`. Feed DTOs returned to v1 controllers MUST omit embedded comment arrays. Vote enrichment (`enrichPostsWithVoteData`) MUST remain.

Feed 组装 MUST NOT 填充评论预览；MUST 保留投票 enrichment。

#### Scenario: 推荐 Feed 无 comments 字段

- **WHEN** 客户端 GET v1 `/feed/recommend`
- **THEN** 每项 MUST NOT 含 `comments` 数组

#### Scenario: 仍返回投票字段

- **WHEN** 登录用户拉取含辩论帖的 Feed
- **THEN** 项 MUST 含 `leftVoteCount`、`rightVoteCount`、`myVoteSide`（若已投）

### Requirement: Feed type filter default SHALL be mixed

When query `type` is empty or omitted, feed MUST NOT default to debate-only; `normalizeFeedTypeFilter` MUST return empty filter (all published types). Explicit `type=moment|debate` MAY still filter when provided.

Feed 默认 MUST 混排；空 type MUST NOT 等同 debate-only。

#### Scenario: 无 type 混排

- **WHEN** GET feed 不带 type 参数
- **THEN** 结果 MUST 含 moment 与 debate 帖

### Requirement: Create post SHALL infer debate from labels

Server create handler MUST reject partial debate labels; accept both labels as debate with optional media; accept neither as moment. MUST remove validation forbidding media on debate posts.

创建 MUST 按标签推断类型；辩论帖 MUST 允许媒体。

#### Scenario: 辩论带媒体入库

- **WHEN** 创建请求两侧标签有效且含 media
- **THEN** 服务端 MUST 写入 debate 行与 media 行

### Requirement: v1 comment list SHALL expose voteSide

`ListComments` (v1 handler) MUST map `debate_vote_side` to DTO `VoteSide` and compute `VoteSideLabel`. Implementation MAY internally use Redis read model (`ListCommentsFromRedis`) but HTTP contract MUST remain v1.

v1 评论读路径 MUST 返回 voteSide。

#### Scenario: MySQL 评论含 debate_vote_side

- **WHEN** v1 GET comments 返回已发布评论
- **THEN** JSON MUST include voteSide when column set

## REMOVED Requirements

### Requirement: UCG v2 HTTP routes for feed and comments

**Reason**: Unused parallel API; clients consolidated to v1 extensions.

**Migration**: Remove route registration for `/ucg/app/api/v2/feed/recommend`, `/v2/feed/following`, `/v2/posts`, `/v2/posts/{id}/comments` (GET/POST). Keep vote and other v1 routes. Document BREAKING for external callers.

#### Scenario: v2 Feed 返回 404

- **WHEN** 客户端请求 `/ucg/app/api/v2/feed/recommend`
- **THEN** gateway MUST NOT 路由至已删除 handler（404 或等价）
