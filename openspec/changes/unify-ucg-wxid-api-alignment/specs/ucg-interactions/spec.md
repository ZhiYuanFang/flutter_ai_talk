## MODIFIED Requirements

### Requirement: MVP interactions SHALL include like, comment, delete own comment, long-press undo own like

The app SHALL support liking posts (`POST /posts/{id}/like`), undoing own like (`DELETE /posts/{id}/like`), commenting (`POST /posts/{id}/comments` with `content`), deleting own comments (`DELETE /comments/{id}`), and long-pressing own like to undo. Follow/unfollow SHALL use `POST /follow/{wxId}` and `DELETE /follow/{wxId}`. Block and report MUST NOT be included in MVP.

#### Scenario: 点赞
- **WHEN** 已登录用户（wxId 非零）点击点赞
- **THEN** App SHALL 调用 `POST /posts/{id}/like` 并更新 UI 为已赞态

#### Scenario: 长按撤销自己的赞
- **WHEN** 已登录用户长按自己的点赞
- **THEN** App SHALL 调用 `DELETE /posts/{id}/like` 并恢复未赞态

#### Scenario: 删除自己的评论
- **WHEN** 用户在本人评论上触发删除
- **THEN** App SHALL 调用 `DELETE /comments/{commentId}` 并从列表移除

#### Scenario: 无拉黑举报入口
- **WHEN** 用户查看帖子或聊天
- **THEN** UI SHALL NOT 提供拉黑或举报入口

### Requirement: Interactions SHALL require login

Like and comment actions MUST require logged-in session with non-zero wxId. Device-only sessions SHALL show bind-wechat gate per `ucg-wxid-identity`.

#### Scenario: 未登录点赞
- **WHEN** 未登录用户点击点赞
- **THEN** App SHALL 引导登录
