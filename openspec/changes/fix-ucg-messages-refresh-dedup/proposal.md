## Why

UCG 消息 Tab 在用户点击「重试」或 Web 上「失焦后再点回页面」时，会重复发起多轮 `fetchConversations` / `fetchCommentNotifications`（实测约 3 次）。根因是 `_refreshAll` 同时 bump provider、本地拉取与 `UcgShell`/`HomeScreen` 的未读校准链路叠加，且 `syncUcgUnreadFromServer` 在 `resumed` 与 `accessToken` 变化时无去重。需合并刷新路径，保证一次用户操作只对应一轮必要的 HTTP 校准。

## What Changes

- 为 `syncUcgUnreadFromServer`（及 Shell `_syncShellUnreadBadge`）增加 in-flight 合并 / 短窗口 debounce，避免同一时刻多路触发重复请求。
- 精简 `UcgMessagesTab._refreshAll`：去掉无效的 `bumpUcgConversationsRefresh` 与会引发 Shell 二次拉取的 `bumpUcgNotificationsRefresh`；改为 `ref.refresh(ucgCommentNotificationsProvider)` + 本地 `_syncUnreadBadge()`。
- 调整 `UcgShell` 对 `ucgNotificationsChangedProvider` 的监听：bump 触发的 provider 刷新与 HTTP 未读校准不重复打相同接口（或复用去重后的 sync）。
- `HomeScreen` 在 `AppLifecycleState.resumed` 时仍可调未读校准，但必须走全局去重入口，且不在用户仅浏览 UCG 消息错误页时产生可感知的「无 UI 变化的多余刷新」（网络层仍只打一轮）。
- **不改动** 后端 API、WS 协议、消息列表分页与滑动操作语义。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-chat-ui`：消息 Tab 手动刷新（重试 / 下拉）与未读校准不得重复请求同一会话列表与互动通知首屏数据。
- `ucg-notifications`：HTTP 未读校准（resume / WS / Tab 切换）须合并并发，避免短时间重复 `GET /notifications/comments` 与 `GET /conversations`。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_messages_tab.dart`、`app/lib/ucg/providers/ucg_providers.dart`、`app/lib/ucg/ui/ucg_shell.dart`；可能微调 `app/lib/ui/home_screen.dart`（resume 调用去重入口）。
- **基线**：引用 `v2.0.2` 中 `ucg-chat-ui`、`ucg-notifications` 并做 delta 扩展。
