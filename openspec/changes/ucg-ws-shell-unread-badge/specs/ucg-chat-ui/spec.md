## MODIFIED Requirements

### Requirement: UCG WebSocket application events SHALL drive global unread resync

When the shared UCG chat WebSocket receives inbound chat message frames (`message`, `message_delivered`, `chat_message`) where the message is not from the current user (`!isMine`), or receives `comment_notification`, the client MUST increment `ucgUnreadCountProvider` locally by one immediately. The client MUST NOT require a synchronous HTTP unread fetch before updating in-app badges for these live events. Absolute unread authority MUST remain HTTP calibration (`syncUcgUnreadFromServer`): it MUST run once per session as a baseline when UCG WebSocket first becomes ready after login, and MUST overwrite local counts on app resume, login transition, after marking conversations or notifications read, when the user opens the 消息 tab, and when the user pull-to-refreshes the messages list. After a successful `markConversationRead`, the client MUST trigger HTTP overwrite even if a prior overwrite already ran in the same chat screen visit.

UCG WebSocket 收到他人私信或 `comment_notification` 时须立即本地 +1；绝对值以 HTTP 为准。本会话首次 WS ready 须 HTTP baseline；resume、登录切换、已读、**进入消息 Tab**、**消息列表下拉刷新** 后须 HTTP 覆盖。同一聊天页多次已读成功后仍须能再次 HTTP 覆盖，不得因「只清一次」长期虚高。

#### Scenario: 他人私信 WS 乐观 +1

- **WHEN** WS 推送 `message_delivered` 且 `senderWxId` 不等于当前登录 wxId
- **THEN** `ucgUnreadCountProvider` SHALL 立即加 1
- **AND** SHALL NOT 阻塞于 `GET /conversations` 完成

#### Scenario: 互动通知 WS 乐观 +1

- **WHEN** WS 推送 `comment_notification`
- **THEN** `ucgUnreadCountProvider` SHALL 立即加 1

#### Scenario: 本人消息不递增

- **WHEN** WS 推送当前用户自己发送的消息确认
- **THEN** 客户端 SHALL NOT 对 `ucgUnreadCountProvider` 做乐观递增

#### Scenario: WS 首次 ready baseline

- **WHEN** 已登录 wx 已绑定且本会话 UCG WebSocket 首次 `ready`
- **THEN** 客户端 SHALL 调用 `syncUcgUnreadFromServer` 一次作为 baseline
- **AND** SHALL NOT 将喂养 Home `_init` 作为 baseline 触发点

#### Scenario: WS 重连不重复 baseline

- **WHEN** 同一会话内 WebSocket 断线重连并再次 ready
- **AND** baseline 已在本会话执行过
- **THEN** 客户端 SHALL NOT 因 ready 再次 baseline HTTP

#### Scenario: 标记已读后 HTTP 覆盖

- **WHEN** 用户打开聊天并 `markConversationRead` 成功
- **THEN** 客户端 SHALL 通过 HTTP 校准更新 `ucgUnreadCountProvider` 以反映已读
- **AND** SHALL NOT 长期保留因乐观 +1 产生的虚高未读

#### Scenario: 同一聊天内再次已读仍覆盖

- **WHEN** 用户在同一 `UcgChatScreen` 访问中再次因新消息成功 `markConversationRead`
- **THEN** 客户端 SHALL 再次触发 HTTP 校准覆盖全局未读
- **AND** MUST NOT 因首次已读标志而跳过后续覆盖

#### Scenario: 消息 Tab 下拉刷新覆盖全局未读

- **WHEN** 用户在消息 Tab 下拉刷新且会话列表与互动首屏均显示无未读
- **THEN** 成功的 HTTP 校准 MUST 将 `ucgUnreadCountProvider` 写为 0（在服务端权威为 0 时）
- **AND** 消息 Tab 红点、悬浮球红点与桌面角标 MUST 随之清除

#### Scenario: 进入消息 Tab 校准

- **WHEN** 用户切换到消息 Tab 且 UCG 主壳会话已激活
- **THEN** 客户端 SHALL 触发 HTTP 未读校准（可与列表刷新合并，但 MUST 写入 `ucgUnreadCountProvider`）

#### Scenario: resume 校准覆盖乐观值

- **WHEN** App 从后台 resume 且 UCG 主壳会话已激活
- **THEN** 客户端 SHALL HTTP 校准未读并覆盖 `ucgUnreadCountProvider`

### Requirement: Messages tab visible unread SHALL drive shell badges

When the messages tab successfully refreshes or reloads its visible conversation list and interaction unread, the client MUST set `ucgUnreadCountProvider` to the sum of visible conversation `unreadCount` values plus the interaction system row `unreadCount`. If that sum is zero, message-tab and square-ball unread indicators MUST clear. This visible-list overwrite MUST run after optional HTTP sync on pull-to-refresh so list parity wins over stale optimistic or failed sync values.

消息 Tab 成功刷新/重载可见会话与互动未读后，**必须**用「可见会话 unread 之和 + 互动 unreadCount」写入 `ucgUnreadCountProvider`；合计为 0 时消息 Tab 与悬浮球角标 **必须** 熄灭。下拉刷新时该覆盖 **必须** 在可选 HTTP sync 之后执行，以保证列表所见优先于虚高乐观值或失败 sync。

#### Scenario: 列表无未读则角标必灭

- **WHEN** 用户下拉刷新消息 Tab 后，各会话行 unread 均为 0 且互动消息行无未读数字
- **THEN** `ucgUnreadCountProvider` MUST 为 0
- **AND** 底部「消息」红点与广场悬浮球红点 MUST 消失

#### Scenario: 离开聊天后列表对齐角标

- **WHEN** 用户从聊天页返回消息 Tab 且首屏会话已重载为无未读、互动亦无未读
- **THEN** 客户端 MUST 按可见列表将全局未读写为 0
- **AND** MUST NOT 因先前 WS 乐观 +1 残留而保持红点
