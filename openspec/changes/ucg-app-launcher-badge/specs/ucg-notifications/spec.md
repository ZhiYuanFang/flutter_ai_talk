## ADDED Requirements

### Requirement: NotifyOnComment SHALL trigger launcher badge push after notification insert

After `NotifyOnComment` successfully inserts one or more `ucg_notification` rows (`comment_on_post` or `mention_in_comment`), ucg-service MUST invoke the launcher badge push hook: send a visible push to the recipient's registered devices with alert body derived from actor nickname (e.g.「{nickname}评论了你的动态」) and `badge = ComputeTotalUnread(recipient_wx_id)`. This MUST occur in the same business flow as notification insert and MUST NOT be skipped when the recipient is WebSocket-connected.

`NotifyOnComment` 成功写入通知行后，必须触发启动器角标可见推送（含 actor 昵称文案与绝对 badge）；收件人 WS 在线时仍须推送。

#### Scenario: 评论帖主后推送

- **WHEN** 用户 A 评论用户 B 的帖子且插入 `comment_on_post` 通知
- **THEN** ucg-service SHALL 向 B 的已注册设备发送可见推送
- **AND** `badge` SHALL 反映 B 更新后的 `totalUnread`

#### Scenario: @ 提及后推送

- **WHEN** 评论解析出 @用户 C 且插入 `mention_in_comment` 通知
- **THEN** ucg-service SHALL 向 C 发送可见推送

#### Scenario: 作者评论自己帖不推送

- **WHEN** 帖子作者在自己帖下评论且不插入通知行
- **THEN** ucg-service SHALL NOT 为此事件发送启动器推送

#### Scenario: 标记已读后发静默推送

- **WHEN** 用户通过 `POST /notifications/comments/read` 减少未读互动数
- **THEN** ucg-service SHALL 按 `ucg-launcher-badge-push` 静默 badge 规则发送推送
