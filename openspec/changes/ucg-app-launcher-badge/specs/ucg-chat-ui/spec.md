## ADDED Requirements

### Requirement: New DM delivery SHALL trigger launcher badge push on server

When ucg-service (or gateway chat pipeline) successfully delivers a new direct message to a recipient, the server MUST invoke the launcher badge push hook: send a visible push to the recipient's registered devices with alert body derived from sender nickname (e.g.「{nickname}发来一条私信」) and `badge = ComputeTotalUnread(recipient_wx_id)`. v1 MUST send push even if the recipient has an active chat WebSocket. v1 MUST NOT collapse multiple messages in the same conversation.

新私信成功投递给收件人后，服务端必须触发可见启动器角标推送（含发送方昵称文案与绝对 badge）；v1 WS 在线仍推送；v1 不折叠同会话消息。

#### Scenario: 收到私信推送

- **WHEN** 用户 B 收到来自 A 的新私信且 B 已 register 推送设备
- **THEN** ucg-service SHALL 向 B 发送可见推送且 alert 含 A 昵称
- **AND** `badge` SHALL 为 B 的 `totalUnread`

#### Scenario: 会话已读后发静默角标

- **WHEN** 用户打开聊天或标记会话已读导致会话 unread 减少
- **THEN** ucg-service SHALL 发送静默 badge 推送至新 `totalUnread`

#### Scenario: 在线 WS 仍发推送

- **WHEN** B 的 UCG chat WebSocket 已连接且 `message_delivered` 已下发
- **THEN** 服务端 SHALL 仍发送启动器角标推送

### Requirement: Client SHALL align in-app unread with server on resume after push

The Flutter client MUST continue to sync `ucgUnreadCountProvider` via WebSocket events and HTTP (`syncUnreadFromWs`, conversation list refresh) on `AppLifecycleState.resumed`. In-app unread indicators (message tab, enter-square tab) MUST use the same OR semantics as server `totalUnread` (conversation unread sum + notification unread). Push callbacks MUST NOT be the sole source of in-app badge state.

客户端 resume 时必须继续经 WS/HTTP 校准应用内未读；语义须与服务端 totalUnread 一致；不得仅依赖推送回调更新应用内状态。

#### Scenario: resume 后 HTTP 校准

- **WHEN** 用户从后台恢复 App（含点击推送冷启动）
- **THEN** App SHALL 触发 `syncUnreadFromWs` 或等价 HTTP 拉取
- **AND** `ucgUnreadCountProvider` SHALL 与会话未读加互动未读 OR 逻辑一致

#### Scenario: 杀进程后角标由推送更新

- **WHEN** App 进程已被杀死且用户收到新私信推送
- **THEN** 系统启动器角标 SHALL 显示推送 payload 中的 `badge` 数字
- **AND** 用户打开 App 后应用内未读 SHALL 经 HTTP/WS 与角标对齐
