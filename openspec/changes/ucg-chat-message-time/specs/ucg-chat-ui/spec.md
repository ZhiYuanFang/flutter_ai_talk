## ADDED Requirements

### Requirement: 聊天消息气泡下方 SHALL 展示 formatHistoryInstant 发送时间

Each message row in `UcgChatScreen` SHALL display a muted timestamp label directly below the message bubble (text, image, video, or combined), aligned with the bubble column (start for peer messages, end for own messages). The label MUST be computed exclusively via `formatHistoryInstant(message.createdAt.toLocal(), DateTime.now())` from `history_line_format.dart`. The client MUST NOT use `DateFormat`, `formatHistoryRelativeAgo`, or chat-specific duplicate formatters for this label.

1:1 聊天页每条消息气泡正下方必须以小号弱化文字展示发送时间；文案必须且仅能调用 `formatHistoryInstant(createdAt.toLocal(), DateTime.now())`；不得使用 `DateFormat`、`formatHistoryRelativeAgo` 或聊天专用重复实现。

#### Scenario: 今日消息显示时分

- **WHEN** 用户查看 `createdAt` 落在本地「今天」的消息
- **THEN** 气泡下方 SHALL 显示 `formatHistoryInstant` 的今日格式（`HH:mm`，24 小时制、两位补零）
- **AND** 时间文字 MUST 位于气泡下方且与气泡同侧对齐

#### Scenario: 昨日消息显示昨天前缀

- **WHEN** 用户查看 `createdAt` 落在本地「昨天」的消息
- **THEN** 气泡下方 SHALL 显示 `昨天HH:mm` 格式（与 `formatHistoryInstant` 一致，无额外空格）

#### Scenario: 同年更早日期

- **WHEN** 用户查看 `createdAt` 与当前同年且早于昨天的消息
- **THEN** 气泡下方 SHALL 显示 `M月D日 HH:mm` 格式（与 `formatHistoryInstant` 一致）

#### Scenario: 跨年消息

- **WHEN** 用户查看 `createdAt` 年份早于当前本地年的消息
- **THEN** 气泡下方 SHALL 显示 `Y年M月D日 HH:mm` 格式

#### Scenario: 己方消息含发送状态

- **WHEN** 用户查看自己发送的消息（含 pending / delivered / failed 状态图标）
- **THEN** 时间标签 SHALL 位于气泡与状态图标整体下方并右对齐
- **AND** SHALL NOT 挤占状态图标与气泡同一行

#### Scenario: 纯媒体与图文混排

- **WHEN** 消息仅含图片或视频，或同时含媒体与文字
- **THEN** 时间标签 SHALL 位于该条消息整块内容（媒体 + 文字）的最下方
- **AND** 仍 MUST 使用 `formatHistoryInstant`

#### Scenario: 会话列表时间不受影响

- **WHEN** 用户在消息 Tab 查看会话列表 `lastMessageAt`
- **THEN** 列表行时间展示 MUST 保持既有 `DateFormat('MM-dd HH:mm')` 行为
- **AND** MUST NOT 改为 `formatHistoryInstant`
