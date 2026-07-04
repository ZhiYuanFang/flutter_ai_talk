## ADDED Requirements

### Requirement: Debate posts SHALL use vote instead of like

For `type=debate` posts, the app MUST NOT render like buttons, like counts, or liker avatar grids. Interaction MUST use vote via `UcgDebateVsBar` on square (interactive) and detail (interactive). Moment posts SHALL retain existing like behavior.

辩论帖 MUST 以投票替代点赞；moment 保持点赞。

#### Scenario: 广场辩论卡无点赞

- **WHEN** 用户浏览广场辩论帖

- **THEN** UI MUST NOT 展示心形或 likeCount

#### Scenario: 详情辩论帖可投票

- **WHEN** 已登录用户打开辩论帖详情

- **THEN** 详情 SHALL 展示 `UcgDebateVsBar` 且 `interactive=true`

## MODIFIED Requirements

### Requirement: MVP interactions SHALL include like, comment, delete own comment, long-press undo own like

The app SHALL support **voting** on debate posts (square inline and detail), **commenting** as arguments (square inline expand, detail full list, profile list hidden), deleting own comments, and follow/unfollow on detail header. **Moment** posts SHALL retain liking from detail page; feed cards for moment MAY show read-only like count. **Debate** feed cards MUST NOT perform like API. Long-press undo own like applies to moment only. Block and report MUST NOT be included in MVP.

辩论帖须支持投票与论点评论；moment 保留点赞；辩论 Feed MUST NOT 调用 like API。

#### Scenario: 详情页 moment 点赞

- **WHEN** 已登录用户在 **moment** 详情页点击心形

- **THEN** App SHALL 调用 `POST/DELETE /posts/{id}/like` 并更新 UI

#### Scenario: Feed 辩论卡只读点赞展示

- **WHEN** 用户在广场查看辩论帖

- **THEN** App MUST NOT 展示点赞 UI 且 MUST NOT 调用 like API

#### Scenario: 详情页评论

- **WHEN** 已登录用户在详情页通过 overflow Comment 或底部输入框提交评论

- **THEN** App SHALL 调用 `POST /posts/{id}/comments` 并 append 至全量评论列表

#### Scenario: 删除自己的评论

- **WHEN** 用户在本人评论上触发删除

- **THEN** App SHALL 调用 `DELETE /comments/{commentId}` 并从列表移除

### Requirement: Interactions SHALL require login

Vote, like (moment only), and comment actions MUST require logged-in session with non-zero wxId. Device-only sessions SHALL show bind-wechat gate per `ucg-wxid-identity`.

投票、评论、moment 点赞均须登录且 wxId 非零。

#### Scenario: 未登录投票

- **WHEN** 未登录用户点击辩论 VS 条

- **THEN** App SHALL 引导登录

#### Scenario: 未登录点赞

- **WHEN** 未登录用户对 moment 帖点击点赞

- **THEN** App SHALL 引导登录

### Requirement: Detail page SHALL show full liker avatars without count and full comments without folding

`UcgPostDetailScreen` for **moment** posts SHALL load and display all likers as an avatar grid beside a heart icon reflecting `likedByMe`, without numeric like count. For **debate** posts, the detail header MUST show `UcgDebateVsBar` instead of liker grid. Comments (arguments) SHALL list **all** items without fold for both types. There SHALL be no「共 N 条评论」title row.

moment 详情展示点赞头像区；debate 详情以 VS 条替代；评论均全量无折叠。

#### Scenario: 辩论详情无点赞区

- **WHEN** 用户打开辩论帖详情

- **THEN** UI SHALL 展示 `UcgDebateVsBar` 且 MUST NOT 展示点赞头像网格

#### Scenario: 评论全量展示

- **WHEN** 帖子评论数大于 5

- **THEN** 详情页 SHALL 默认展示全部评论且无折叠控件
