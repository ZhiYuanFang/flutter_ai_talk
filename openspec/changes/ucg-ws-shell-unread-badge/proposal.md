## Why

UCG 聊天 WebSocket 目前挂在喂养页启动传输上激活，与主壳已负责的历史 WS / resume 不对称；冷启落在预测页时未读校准门闸与实时推送容易错位。消息页对连接失败静默无感知。同时 `ucgUnreadCountProvider` 以 WS 乐观 +1 为主、HTTP 覆盖时机不足，导致私信列表已无未读时消息 Tab / 悬浮球 / 桌面角标仍亮。消息 Tab 与悬浮球红点随主题 primary 变色，不符合「未读固定红」预期。

## What Changes

- 将 UCG chat WS 会话激活（`activateUcgHomeSession`）改到 **主壳 `UcgHomeShell`** 在登录门闸完成后触发；喂养页 **不再** 负责 UCG 建连。
- 在 UCG **消息 Tab** 展示 chat WS 连接态横条：**连接中**（`autoReconnecting` / 有 desired 时的 `disconnected`）与 **连接失败**（`gaveUp`，可点击调用既有 `reconnectChatWebSocket(resetStrike: true)`）。**不改** `ResilientWebSocketClient` 重试 / strike / gaveUp 策略。
- 加固未读数字：绝对值以 HTTP 校准为权威；**消息列表可见未读与角标必须一致**（列表无未读则 Tab/悬浮球角标必灭，以 `applyUcgUnreadFromVisibleList` 覆盖虚高）；用户主动刷新、进消息 Tab、离开聊天 / 互动已读后必须覆盖 `ucgUnreadCountProvider`；修正 single-flight「只等不补」导致旧值残留；消息 Tab / 悬浮球未读点改为 **固定红色**（经 `AppColor` 语义入口，不跟主题 primary）。
- 桌面角标仍由 `ucgUnreadCountProvider` → `FlutterAppBadger` 驱动（颜色由系统决定，本变更不改）。

## Capabilities

### New Capabilities

- `ucg-messages-ws-status`：消息 Tab 展示 UCG chat WS 连接中 / 连接失败态及 gaveUp 手动重连入口（不改变传输重试策略）。
- `ucg-unread-badge-chrome`：消息 Tab 与预测页广场悬浮球未读红点固定红色（不跟主题 primary）；经 `AppColor` 语义入口。

### Modified Capabilities

- `ucg-home-entry`：UCG chat 会话激活与首轮 HTTP 未读校准从「喂养页激活 repository」改为主壳 `UcgHomeShell` 登录门闸完成后触发；喂养页 MUST NOT 再负责 UCG 建连。
- `ucg-chat-ui`：强化 HTTP 为未读绝对值权威；下拉刷新 / 进消息 Tab / 离开聊天与互动已读后 MUST 覆盖本地计数；single-flight 合并后 MUST 补跑未决校准；保留 WS 乐观 +1。
- `ucg-shell-navigation`：与主壳激活对齐——chat WS desired 随主壳 UCG 会话，不得仅依赖喂养页 mount；消息 Tab 红点样式指向 `ucg-unread-badge-chrome`。
- `ucg-notifications`：HTTP 未读校准 single-flight 在 in-flight 结束后若有未决请求 MUST 再跑一轮，避免已读覆盖丢失。

## Impact

- Flutter：`ucg_providers.dart`（activate / sync 门闸与 single-flight）、`ucg_home_shell.dart`、`home_screen.dart`（移除 UCG mount）、`ucg_messages_tab.dart`（连接态横条）、`ucg_visual_widgets.dart` / `ucg_square_edge_dock.dart`（红点色）、`app_color.dart` 增加未读点语义色。
- 不改 Go / 推送注册 / `ResilientWebSocketClient` 退避参数。
- 不新建 `**/test/**`。
