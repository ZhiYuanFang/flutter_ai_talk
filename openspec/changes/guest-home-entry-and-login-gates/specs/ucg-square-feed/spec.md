## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated post lists using query parameters `page` and `pageSize` consistent with existing app APIs. Cards SHALL use WeChat-moments style layout (avatar, nickname, text, media grid/video, time, interaction bar). Sub-tab switching MUST comply with `ucg-visual-system` immersive layout: inline segmented pills on `shellColor`, NOT a separated Material `TabBar` / contrasting header band.

#### Scenario: 推荐 Feed 分页加载

- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 请求下一页并 append 至列表

#### Scenario: 未登录浏览推荐

- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示推荐 Feed

### Requirement: 关注 Tab empty state SHALL guide discovery without login wall

When the user is on the 关注 sub-tab and either (a) is not logged in, or (b) is logged in and the following feed API returns an empty list, the app SHALL show a unified empty state with discovery copy and MUST NOT show a login prompt page or primary action button on that empty state. 关注 Tab 在未登录或已登录但关注列表为空时，MUST 展示统一发现引导空态：`title` 为「还没有关注的人」，`subtitle` 为「去推荐看看，点击动态中的头像进入主页，关注你感兴趣的人」；不得展示「去登录」按钮或其他 `action` 按钮。

#### Scenario: 未登录切换到关注 Tab

- **WHEN** 未登录用户切换到关注 Tab
- **THEN** App SHALL 展示上述统一空态，且 SHALL NOT 发起 `/feed/following` 请求，且 SHALL NOT 展示推荐 Tab 的帖子列表

#### Scenario: 已登录关注列表为空

- **WHEN** 已登录用户位于关注 Tab 且 `/feed/following` 返回空列表
- **THEN** App SHALL 展示与未登录相同的统一空态文案（无按钮）

#### Scenario: 已登录关注列表有内容

- **WHEN** 已登录用户位于关注 Tab 且 following feed 返回帖子
- **THEN** App SHALL 展示瀑布流列表（行为不变）

### Requirement: Feed SHALL hide non-published posts from non-authors

Client SHALL only render posts with `status=published` for other users' content. Author's own pending/rejected posts SHALL appear only in 我的动态, not in public feeds.

#### Scenario: 他人审核中帖子不可见

- **WHEN** 推荐 Feed 返回的数据不含他人 pending 帖
- **THEN** UI SHALL NOT 展示他人审核中内容

## REMOVED Requirements

### Requirement: 关注 Feed SHALL require login

**Reason**: 产品改为关注 Tab 对游客展示发现引导空态，登录门控移至点赞/关注/发布等操作点。

**Migration**: 未登录用户仍可切换关注 Tab，但不调用 following API；通过推荐流点头像进入他人主页后再触发登录 gate 完成关注。

#### Scenario: 未登录打开关注

- **WHEN** （已移除）未登录用户切换到关注 Tab 时展示登录引导
- **THEN** （由「关注 Tab empty state SHALL guide discovery without login wall」替代）
