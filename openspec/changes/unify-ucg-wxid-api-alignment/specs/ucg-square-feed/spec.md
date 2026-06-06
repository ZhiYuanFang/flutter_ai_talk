## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated post lists using query parameters `page` and `pageSize` consistent with existing app APIs. 推荐 SHALL call `GET /ucg/app/api/feed/recommend`; 关注 SHALL call `GET /ucg/app/api/feed/following`. Cards SHALL use WeChat-moments style layout (avatar, nickname, text, media grid/video, time, interaction bar). Sub-tab switching MUST comply with `ucg-visual-system` immersive layout: inline segmented pills on `shellColor`, NOT a separated Material `TabBar` / contrasting header band.

#### Scenario: 推荐 Feed 分页加载
- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 请求 `GET /feed/recommend` 下一页并 append 至列表

#### Scenario: 未登录浏览推荐
- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示推荐 Feed

### Requirement: Feed SHALL hide non-published posts from non-authors

Client SHALL only render posts with published status for other users' content. Author's own pending/rejected posts SHALL appear only in 我的动态, not in public feeds. Status MUST be parsed from ucg-service integer enum (e.g. `2` = published) per `ucg-api-contract`.

#### Scenario: 他人审核中帖子不可见
- **WHEN** 推荐 Feed 返回的数据不含他人 pending 帖
- **THEN** UI SHALL NOT 展示他人审核中内容

#### Scenario: 整型 status 已发布
- **WHEN** Feed 项 `status` 为整型 `2`
- **THEN** Client SHALL 视为已发布并在推荐/关注流展示（作者本人除外 pending/rejected 规则不变）
