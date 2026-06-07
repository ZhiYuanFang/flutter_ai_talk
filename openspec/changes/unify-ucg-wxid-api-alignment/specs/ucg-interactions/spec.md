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

### Requirement: Feed posts SHALL expose likedByMe for authenticated viewers

When the request carries a valid logged-in wxId (non-zero `X-Internal-Wx-Id`), feed list items (`GET /feed/recommend`, `GET /feed/following`) SHALL include `likedByMe: true|false` per post based on server-side `ucg_post_like` records. Anonymous or device-only (`sub=0`) requests SHALL omit personalized like state (`likedByMe` false). Client SHALL parse `likedByMe` (alias `liked`) and render heart highlight accordingly after reload.

#### Scenario: 已登录重新进入广场
- **WHEN** 已登录用户点赞帖子后退出并重新进入 UCG 广场推荐或关注 Tab
- **THEN** Feed 响应 SHALL 对曾点赞的帖子返回 `likedByMe: true`，UI SHALL 展示已赞态

#### Scenario: 未登录推荐流
- **WHEN** 未登录用户加载推荐 Feed
- **THEN** 请求 MAY 不带 Bearer；响应中 `likedByMe` SHALL 为 false

### Requirement: Feed engagement block SHALL show liker avatar grid

When a post has `likeCount > 0`, the Moments-style engagement block SHALL lazy-load likers via `GET /posts/{id}/likes` (paginated, server profile from `GetPublicProfile` including `avatarKey`/`avatarUrl` when available) and display a wrapping grid of liker avatars (rounded square radius 5, 2px gap). Tapping an avatar SHALL open `UcgUserProfileScreen` for that `wxId`. Missing avatars SHALL show a themed placeholder. While loading, a compact spinner MAY appear; on failure, fallback to count summary (`N 人`).

#### Scenario: 帖子有点赞
- **WHEN** 用户浏览 `likeCount > 0` 的帖子
- **THEN** App SHALL 请求点赞名单并在灰底块以头像网格展示点赞用户

#### Scenario: 点击点赞头像
- **WHEN** 用户点击灰底块中某点赞者头像
- **THEN** App SHALL 打开该用户主页（`UcgUserProfileScreen`）

#### Scenario: 点赞名单 API 返回头像
- **WHEN** 客户端请求 `GET /posts/{id}/likes`
- **THEN** ucg-service SHALL 在 `list[]` 每项返回 `wxId`、`nickname`，并在用户有头像时返回 `avatarKey` 与 CDN `avatarUrl`（经 `GetPublicProfile`，与 profile/帖子作者 enrichment 一致）

### Requirement: Interactions SHALL require login

Like and comment actions MUST require logged-in session with non-zero wxId. Device-only sessions SHALL show bind-wechat gate per `ucg-wxid-identity`.

#### Scenario: 未登录点赞
- **WHEN** 未登录用户点击点赞
- **THEN** App SHALL 引导登录

#### Scenario: 他人主页取消关注
- **WHEN** 已登录用户在其已关注用户的主页点击「取消关注」
- **THEN** App SHALL 调用 `DELETE /follow/{wxId}`、刷新 `isFollowing` 与「我的」`followingCount`

#### Scenario: 聊天顶栏关注切换
- **WHEN** 已登录用户（wxId 非零）在 1:1 聊天顶栏点击「关注」或「已关注」
- **THEN** App SHALL 分别调用 `POST /follow/{peerWxId}` 或 `DELETE /follow/{peerWxId}`、更新顶栏按钮态并刷新「我的」`followingCount`

#### Scenario: 设备态聊天关注门控
- **WHEN** `sub=0` 用户在聊天顶栏点击关注按钮
- **THEN** App SHALL 展示绑定微信提示，且 SHALL NOT 调用 follow API
