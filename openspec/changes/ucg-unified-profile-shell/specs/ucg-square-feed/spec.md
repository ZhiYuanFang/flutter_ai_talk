## ADDED Requirements

### Requirement: Feed avatar tap SHALL open UcgUserProfileScreen for all authors including self

Tapping the author avatar on square Feed masonry cards (recommended and following) MUST navigate to `UcgUserProfileScreen(userId: authorId)` for **every** author, including when `authorId` equals the current user's wxId. The App MUST NOT switch Shell tab to 我的 and MUST NOT use a separate self-only navigation branch.

广场 Feed 卡片头像点击必须统一进入 `UcgUserProfileScreen`，含点击自己头像，不得跳转「我的」Tab。

#### Scenario: 点击他人头像
- **WHEN** 用户在广场 Feed 点击帖子作者头像且作者非本人
- **THEN** App SHALL push `UcgUserProfileScreen(userId: authorId)`

#### Scenario: 点击自己头像
- **WHEN** 用户在广场 Feed 点击帖子作者头像且 `authorId` 等于当前登录 wxId
- **THEN** App SHALL push `UcgUserProfileScreen(userId: authorId)`
- **AND** App SHALL NOT 切换 Shell 至「我的」Tab
- **AND** App SHALL NOT 使用仅针对本人的特殊路由分支

#### Scenario: 与详情页头像行为一致
- **WHEN** 用户从 Feed 或详情页点头像
- **THEN** 两者 SHALL 使用相同的 `UcgUserProfileScreen` 导航方式
