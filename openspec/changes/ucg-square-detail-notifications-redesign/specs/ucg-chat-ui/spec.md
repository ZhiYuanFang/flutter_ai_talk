## ADDED Requirements

### Requirement: 消息 Tab SHALL show virtual 互动消息 system conversation row

The 消息 tab conversation list SHALL include a **virtual system row** pinned at the top titled **互动消息**, aggregating comment and `@` mention notifications (unified inbox entry). This row SHALL NOT map to a real `ucg_conversation` id. It SHALL display an unread badge when `unreadCount > 0` from `GET /notifications/comments`. Tapping the row SHALL navigate to `UcgInteractionInboxScreen`. The flat inline notification list previously embedded above conversations is **superseded** and MUST NOT remain.

#### Scenario: 展示虚拟系统行
- **WHEN** 已登录用户打开消息 Tab
- **THEN** App SHALL 在会话列表顶部展示「互动消息」系统行（位于私信会话之上）

#### Scenario: 系统行未读角标
- **WHEN** 存在未读 comment/mention 通知
- **THEN** 系统行 SHALL 展示未读角标

#### Scenario: 点击进入 Inbox
- **WHEN** 用户点击「互动消息」系统行
- **THEN** App SHALL 打开 `UcgInteractionInboxScreen`

### Requirement: UcgInteractionInboxScreen SHALL list notifications with post thumb and pagination

`UcgInteractionInboxScreen` SHALL fetch `GET /notifications/comments` with pagination (load more on scroll). The AppBar SHALL include **全部已读** which calls `POST /notifications/comments/read` with `{ "all": true }`. Each list row SHALL show: actor avatar, nickname, **2-line** comment preview (display layer hides `#wxId` suffix), relative time, unread dot when applicable, and a **square** post thumbnail from `postThumbUrl` on the trailing edge (placeholder when empty). Tapping a row SHALL navigate to `UcgPostDetailScreen(postId)` and mark that notification read via `{ "ids": [id] }`.

#### Scenario: Inbox 列表行布局
- **WHEN** 用户打开互动消息 Inbox 且存在通知
- **THEN** 每行 SHALL 展示 actor 头像、昵称、最多 2 行 preview 及右侧方形帖子缩略图

#### Scenario: 全部已读
- **WHEN** 用户点击 Inbox 顶栏「全部已读」
- **THEN** App SHALL POST `{ "all": true }` 并刷新列表与未读计数

#### Scenario: Inbox 分页
- **WHEN** 用户滚动至 Inbox 列表底部且仍有下一页
- **THEN** App SHALL 请求下一页 `GET /notifications/comments` 并 append

#### Scenario: 点击 Inbox 条目进详情
- **WHEN** 用户点击某条互动消息
- **THEN** App SHALL 打开对应 `postId` 的 `UcgPostDetailScreen` 且 SHALL NOT 打开私信页

#### Scenario: @ 通知不打开私信
- **WHEN** 用户收到 `mention_in_comment` 通知并点击
- **THEN** App SHALL 打开帖子详情且 SHALL NOT 自动进入与 mentioner 的聊天页

## MODIFIED Requirements

### Requirement: 消息列表 SHALL support WeChat-style swipe actions

Conversation list behavior unchanged (pin, delete, unread dot). The private-message (`GET /conversations`) list SHALL support pagination consistent with inbox pagination. When comment notification `unreadCount > 0` **or** any conversation has unread messages, the shell bottom **消息** tab icon SHALL show an unread indicator (OR logic). The virtual 互动消息 system row MAY show its own unread badge in addition to the shell-level dot.

#### Scenario: Shell 未读红点
- **WHEN** 存在未读会话或未读互动消息（任意 UCG Tab）
- **THEN** 底部「消息」图标 SHALL 显示红点或角标

#### Scenario: 私信列表分页
- **WHEN** 用户滚动消息 Tab 私信列表至底部且仍有下一页
- **THEN** App SHALL 请求下一页 conversations 并 append
