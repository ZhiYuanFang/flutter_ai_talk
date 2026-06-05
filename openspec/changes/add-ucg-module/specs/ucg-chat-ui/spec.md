## ADDED Requirements

### Requirement: 消息 Tab SHALL connect WebSocket via gateway-app on same host as apiBaseUrl

Chat WebSocket MUST connect to gateway-app path `/ucg/app/ws/chat` on the same host as `AppEnv.apiBaseUrl`. URL SHALL be derived via `wsUcgChatUrlEffective` (mirroring `wsHistoryUrlEffective`), with optional override via `WS_UCG_CHAT_URL` (`--dart-define`). Connection SHALL follow auth-first-frame pattern similar to `RemoteFeedRepository` (JWT in first JSON frame). Client MUST NOT connect directly to ucg-service or use a separate UCG WS domain.

#### Scenario: WS 经 gateway 同域
- **WHEN** 已登录用户进入消息 Tab 且 `apiBaseUrl` 为 `https://api.example.com`
- **THEN** Client SHALL 连接 `wss://api.example.com/ucg/app/ws/chat`（或含 path 前缀的等价 URL），且 SHALL NOT 直连 ucg-service 独立域名

#### Scenario: WS URL 可选手动覆盖
- **WHEN** 构建时设置 `--dart-define=WS_UCG_CHAT_URL=wss://custom.example/ucg/app/ws/chat`
- **THEN** `wsUcgChatUrlEffective` SHALL 返回该 override 值

### Requirement: 消息列表 SHALL support WeChat-style swipe actions

Conversation list SHALL show unread red dot on 消息 tab when any unread > 0. List items SHALL support swipe to pin and delete (client-side or API-backed per backend spec).

#### Scenario: 未读红点
- **WHEN** 存在未读会话
- **THEN** 底部「消息」图标 SHALL 显示红点

#### Scenario: 1:1 聊天支持多媒体
- **WHEN** 用户在聊天页发送文本/图片/视频
- **THEN** App SHALL 通过 WS 发送并在 UI 展示 pending/delivered/failed 状态

### Requirement: Messaging SHALL require login

Opening 消息 tab or chat MUST require login.

#### Scenario: 未登录消息
- **WHEN** 未登录用户点击消息 Tab
- **THEN** App SHALL 引导登录
