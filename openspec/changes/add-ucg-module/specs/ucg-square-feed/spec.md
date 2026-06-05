## ADDED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated post lists using query parameters `page` and `pageSize` consistent with existing app APIs. Cards SHALL use WeChat-moments style layout (avatar, nickname, text, media grid/video, time, interaction bar). Sub-tab switching MUST comply with `ucg-visual-system` immersive layout: inline segmented pills on `shellColor`, NOT a separated Material `TabBar` / contrasting header band.

#### Scenario: 推荐 Feed 分页加载
- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 请求下一页并 append 至列表

#### Scenario: 未登录浏览推荐
- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示推荐 Feed

### Requirement: 关注 Feed SHALL require login

The 关注 tab MUST require login. When user is not logged in, the app SHALL show login prompt instead of calling following feed API.

#### Scenario: 未登录打开关注
- **WHEN** 未登录用户切换到关注 Tab
- **THEN** App SHALL 展示登录引导，且 SHALL NOT 发起 `/feed/following` 请求

### Requirement: Feed SHALL hide non-published posts from non-authors

Client SHALL only render posts with `status=published` for other users' content. Author's own pending/rejected posts SHALL appear only in 我的动态, not in public feeds.

#### Scenario: 他人审核中帖子不可见
- **WHEN** 推荐 Feed 返回的数据不含他人 pending 帖
- **THEN** UI SHALL NOT 展示他人审核中内容
