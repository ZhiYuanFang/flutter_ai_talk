## ADDED Requirements

### Requirement: 消息 Tab SHALL surface 互动消息 section for comment notifications

The 消息 tab SHALL include a **互动消息** section (above or alongside the conversation list) listing comment and `@` mention notifications from `GET /notifications/comments`. Each row SHALL show actor avatar, nickname, notification type hint, preview text, and relative time. Tapping a row SHALL navigate to `UcgPostDetailScreen` for the related `postId`. Opening the section or tapping an item SHALL mark relevant notifications read via `POST /notifications/comments/read`. This section MUST NOT create DM threads for mentions (Option A).

#### Scenario: 展示互动消息列表
- **WHEN** 已登录用户打开消息 Tab 且存在评论/@ 通知
- **THEN** App SHALL 在「互动消息」区块展示通知行

#### Scenario: 点击通知进详情
- **WHEN** 用户点击某条互动消息
- **THEN** App SHALL 打开对应 `postId` 的帖子详情页

#### Scenario: 标记已读
- **WHEN** 用户查看互动消息或点击某条
- **THEN** App SHALL 调用 read API 并更新未读展示

#### Scenario: @ 通知不打开私信
- **WHEN** 用户收到 `mention_in_comment` 通知并点击
- **THEN** App SHALL 打开帖子详情且 SHALL NOT 自动进入与 mentioner 的聊天页

## MODIFIED Requirements

### Requirement: 消息列表 SHALL support WeChat-style swipe actions

Conversation list behavior unchanged (pin, delete, unread dot). Additionally, when comment notification `unreadCount > 0`, the 消息 tab icon MAY show unread indicator combined with conversation unread (OR logic). 互动消息 section SHALL show its own unread badge when applicable.

#### Scenario: 未读红点
- **WHEN** 存在未读会话或未读互动消息
- **THEN** 底部「消息」图标 SHALL 显示红点或角标
