## MODIFIED Requirements

### Requirement: UCG shell SHALL maintain WebSocket while shell is mounted

UCG chat WebSocket `setConnectionDesired(true)` MUST be owned by the **home pager shell session** (`activateUcgHomeSession` from `UcgHomeShell` after login gate), not by mounting the feeding page and not solely by selecting the 消息 tab. While the home session is active and the user has a bound wxId, desired MUST remain true when the user is on prediction, feeding, or UCG pages. Leaving the UCG PageView page back to prediction MUST NOT by itself set desired false. Desired MUST become false on home shell release / logout (`deactivateUcgHomeSession`). WebSocket connection MUST NOT be gated solely on selecting the 消息 tab index. Inbound `comment_notification` frames MUST still refresh notification providers and unread badge counts in addition to chat message frames.

UCG chat WS desired **必须** 由主壳会话激活持有，**不得** 绑喂养页 mount，也 **不得** 仅因选中消息 Tab 才连接。主壳会话活跃且 wx 已绑定时，预测 / 喂养 / UCG 页均应保持 desired；仅离开 UCG 子页回预测 **必须 NOT** 单独断连；主壳 release / 登出才 deactivate。`comment_notification` 仍须刷新未读。

#### Scenario: 预测页仍保持 WS

- **WHEN** 已登录 wx 已绑定且主壳 UCG 会话已激活，用户停留在智能预测页
- **THEN** App SHALL 保持 chat WS connection desired=true

#### Scenario: 非消息 Tab 仍保持 WS

- **WHEN** 已登录用户在 UCG Shell 且当前 Tab 为广场或我的
- **THEN** App SHALL 保持 WS 连接 desired=true

#### Scenario: comment_notification 刷新未读

- **WHEN** UCG chat WS 收到 `type=comment_notification`
- **THEN** App SHALL invalidate 互动消息 provider 并更新 Shell 底部「消息」未读红点

#### Scenario: 离开主壳才断开 WS

- **WHEN** 用户离开主壳（登出或 `releasePangbaoHomeTransports`）
- **THEN** App SHALL 经由 `deactivateUcgHomeSession` 设置 desired=false

#### Scenario: 仅离开 UCG 页不断连

- **WHEN** 用户从 UCG PageView 页滑回预测页且主壳仍挂载
- **THEN** App MUST NOT 仅因此将 chat WS desired 设为 false

### Requirement: Shell bottom navigation 消息 item SHALL reflect combined unread

The bottom navigation **消息** item unread dot SHALL use OR logic: show when any conversation has unread messages **or** comment/mention notification `unreadCount > 0` (via `ucgUnreadCountProvider`). This indicator SHALL be visible regardless of which shell tab is selected. The dot color MUST follow `ucg-unread-badge-chrome` (fixed red via `AppColor`), not theme primary.

底部「消息」未读点仍为会话未读与互动未读 OR（经 `ucgUnreadCountProvider`）；任意 Tab 可见。颜色须符合 `ucg-unread-badge-chrome` 固定红。

#### Scenario: 广场 Tab 时互动未读仍显示红点

- **WHEN** 用户位于广场 Tab 且存在未读互动消息
- **THEN** 底部「消息」图标 SHALL 显示未读红点

#### Scenario: 红点为固定红

- **WHEN** 消息 Tab 显示未读红点
- **THEN** 红点颜色 MUST 为 `AppColor` 未读语义固定红
- **AND** MUST NOT 使用主题 primary
