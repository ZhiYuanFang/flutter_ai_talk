## ADDED Requirements

### Requirement: UCG shell SHALL maintain WebSocket while shell is mounted

When the user is inside `UcgShell` with a bound wxId, the app SHALL call `setWsConnectionDesired(true)` on shell mount and `setWsConnectionDesired(false)` when leaving the shell. WebSocket connection MUST NOT be gated solely on selecting the 消息 tab index. The shell WS client SHALL listen for `comment_notification` frames and refresh notification providers and unread badge counts in addition to chat message frames.

#### Scenario: 非消息 Tab 仍保持 WS
- **WHEN** 已登录用户在 UCG Shell 且当前 Tab 为广场或我的
- **THEN** App SHALL 保持 WS 连接 desired=true

#### Scenario: comment_notification 刷新未读
- **WHEN** Shell WS 收到 `type=comment_notification`
- **THEN** App SHALL invalidate 互动消息 provider 并更新 Shell 底部「消息」未读红点

#### Scenario: 离开 Shell 断开 WS
- **WHEN** 用户退出 UCG Shell 页面
- **THEN** App SHALL 设置 `setWsConnectionDesired(false)`

### Requirement: Shell bottom navigation 消息 item SHALL reflect combined unread

The bottom navigation **消息** item unread dot SHALL use OR logic: show when any conversation has unread messages **or** comment/mention notification `unreadCount > 0`. This indicator SHALL be visible regardless of which shell tab is selected.

#### Scenario: 广场 Tab 时互动未读仍显示红点
- **WHEN** 用户位于广场 Tab 且存在未读互动消息
- **THEN** 底部「消息」图标 SHALL 显示未读红点
