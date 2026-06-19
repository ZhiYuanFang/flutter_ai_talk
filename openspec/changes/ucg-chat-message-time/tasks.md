## 1. 聊天消息时间展示（`ucg-chat-ui`）

- [x] 1.1 在 `ucg_chat_screen.dart` import `history_line_format.dart`，封装 `_chatTimeLabel(UcgChatMessage m)` 调用 `formatHistoryInstant(m.createdAt.toLocal(), DateTime.now())`
- [x] 1.2 重构 `_ChatBubble`：各分支（纯文本、纯媒体、图文、己方/对方）在气泡块外包 `Column`，下方追加弱化时间 `Text`（fontSize ~10–11，alpha ~0.45，top padding 4）
- [x] 1.3 己方消息：时间位于 `Row(气泡 + 状态图标)` 下方并右对齐；对方消息左对齐
- [x] 1.4 确认 `createdAt` 为 epoch 0 或异常时不展示时间或展示空（避免 `1970` 文案）

## 2. 范围隔离

- [x] 2.1 确认 `ucg_messages_tab.dart`、`ucg_interaction_inbox_screen.dart` 等未改动，仍用 `DateFormat('MM-dd HH:mm')`

## 3. 验证

- [x] 3.1 `dart analyze` 变更文件无新增 error
- [ ] 3.2 手工：今日/昨日/较早消息时间格式与喂养历史 `formatHistoryInstant` 一致
- [ ] 3.3 手工：图片/视频/图文、己方 pending 与 failed 布局正常；会话列表时间格式未变
