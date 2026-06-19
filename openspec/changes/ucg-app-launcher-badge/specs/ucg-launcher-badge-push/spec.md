## ADDED Requirements

### Requirement: Server SHALL compute absolute total unread for push badge

ucg-service MUST compute `totalUnread(wxId)` as the sum of all conversation `unread_count` for the recipient plus the count of `ucg_notification` rows where `recipient_wx_id = wxId` and `read_at IS NULL`. Every push payload `badge` field MUST be this absolute total, not a delta.

服务端必须按会话未读之和加未读互动通知数计算绝对未读总数；推送 badge 必须为绝对值而非增量。

#### Scenario: 私信与互动合计

- **WHEN** 用户有 2 条会话未读且 1 条未读互动通知
- **THEN** `totalUnread` SHALL 等于 3
- **AND** 下一条推送的 `badge` SHALL 为 3

#### Scenario: 全部已读为零

- **WHEN** 用户所有会话与互动通知均已读
- **THEN** `totalUnread` SHALL 为 0

### Requirement: Server SHALL send visible push with alert and badge on new unread events

On new DM delivery to a recipient and on new `comment_on_post` / `mention_in_comment` notification insert, ucg-service SHALL send a **visible** push to all registered devices for that `wx_id` via the device's `channel` (APNs, HMS, or MiPush). The push MUST include localized alert body (e.g.「{nickname}发来一条私信」「{nickname}评论了你的动态」) and `badge = totalUnread`. v1 MUST send push even when the recipient has an active WebSocket session. v1 MUST NOT collapse multiple DMs in the same conversation into one notification.

新私信或新互动通知写入后，服务端必须向该用户全部已注册设备发送可见推送（含 alert 文案与绝对 badge）；v1 在线 WS 已投递仍推送；v1 不折叠同会话多条 DM。

#### Scenario: 新私信可见推送

- **WHEN** 用户 B 收到来自用户 A 的新私信且 B 已 register 设备
- **THEN** ucg-service SHALL 向 B 的各设备发送可见推送
- **AND** alert body SHALL 含 A 的昵称与「发来一条私信」类文案
- **AND** `badge` SHALL 为 B 的当前 `totalUnread`

#### Scenario: 新评论通知可见推送

- **WHEN** `NotifyOnComment` 成功插入 `comment_on_post` 通知
- **THEN** ucg-service SHALL 向收件人发送可见推送
- **AND** alert body SHALL 含 actor 昵称与「评论了你的动态」类文案

#### Scenario: WS 在线仍推送

- **WHEN** 收件人 WebSocket 已连接且 `message_delivered` 已下发
- **THEN** ucg-service SHALL 仍发送启动器角标推送

#### Scenario: 多设备 fan-out

- **WHEN** 同一 wxId 在 iPhone 与华为手机各 register 一台设备
- **THEN** ucg-service SHALL 向两条 `ucg_push_device` 记录各发一次推送

### Requirement: Server SHALL send silent badge-only push on read degradation

When unread count decreases (single notification marked read, all notifications marked read, or conversation marked read), ucg-service SHALL send a **silent** push updating `badge` to the new `totalUnread` without alert/title text. When `totalUnread` is 0, `badge` MUST be 0.

未读减少或全部已读时，服务端必须发送静默推送仅更新 badge，不得展示打扰性 alert；全部已读时 badge 为 0。

#### Scenario: 单条互动通知已读

- **WHEN** 用户 POST `/notifications/comments/read` 含单条 id
- **THEN** ucg-service SHALL 发送静默推送且 `badge` 等于更新后 `totalUnread`
- **AND** SHALL NOT 含可见 alert 文案

#### Scenario: 全部已读角标清零

- **WHEN** 用户 POST `{ "all": true }` 且所有会话也已读
- **THEN** 静默推送 `badge` SHALL 为 0

#### Scenario: 打开聊天标记会话已读

- **WHEN** 业务层将会话 unread 清零
- **THEN** ucg-service SHALL 发送静默 badge 更新

### Requirement: Push dispatcher SHALL use channel-specific senders without FCM

ucg-service MUST implement `ApnsSender`, `HmsSender`, and `MipushSender` behind a common dispatcher. The system MUST NOT use FCM. On vendor-reported invalid token, ucg-service SHALL delete the corresponding `ucg_push_device` row.

推送必须经过 APNs/HMS/MiPush 适配层发送，不得使用 FCM；无效 token 须清理设备行。

#### Scenario: APNs 发送 iOS 设备

- **WHEN** 目标行 `channel=apns`
- **THEN** dispatcher SHALL 使用 APNs 协议发送且 payload 含 `badge`

#### Scenario: 无效 token 清理

- **WHEN** 厂商 API 返回 token 无效
- **THEN** ucg-service SHALL 删除该 `ucg_push_device` 行
- **AND** SHALL 记录错误日志

#### Scenario: 不使用 FCM

- **WHEN** 任意推送发送路径
- **THEN** 系统 SHALL NOT 调用 Firebase Cloud Messaging
