## Why

1:1 聊天窗口当前仅在气泡旁展示头像与发送状态，用户无法判断每条消息的发送时刻，长对话或隔日续聊时上下文不清晰。喂养主页历史已统一使用 `formatHistoryInstant` 表达本地自然日时间，聊天页应采用同一工具函数以保持「对话内时间」语义一致；会话列表、Feed 等其它表面的 `MM-dd HH:mm` 展示不在本次范围。

## What Changes

- 在 `UcgChatScreen` 每条消息气泡**下方**以小号弱化文字展示发送时间。
- 时间文案 MUST 调用 `formatHistoryInstant(createdAt.toLocal(), DateTime.now())`，与喂养历史行内时间规则一致（今天 `HH:mm`、昨天 `昨天HH:mm`、同年 `M月D日 HH:mm`、跨年 `Y年M月D日 HH:mm`）。
- 覆盖纯文本、纯媒体、图文混排及己方/对方消息；pending 乐观消息使用既有 `createdAt`（本地 `DateTime.now()`）。
- **不在本次范围**：会话列表 `lastMessageAt`、互动收件箱、广场/瀑布流/详情帖时间、后端 API、`formatHistoryRelativeAgo`（刚刚/分前）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-chat-ui`：新增「聊天消息气泡下方展示发送时间」需求，格式化规则绑定 `formatHistoryInstant`。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_chat_screen.dart`（`_ChatBubble` 或等价消息行结构）；新增对 `app/lib/data/history_line_format.dart` 的 import。
- **后端 / API**：无变更。
- **基线**：delta 扩展 `v2.0.2` `ucg-chat-ui`；不修改 `ucg-messages-tab` 等其它能力。
