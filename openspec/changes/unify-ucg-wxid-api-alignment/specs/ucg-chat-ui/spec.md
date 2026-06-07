## ADDED Requirements

### Requirement: App SHALL support creating conversations via POST /conversations

Before or when starting a 1:1 chat, the client MUST be able to call `POST /ucg/app/api/conversations` with peer `wxId` (per ucg-service body schema) to obtain or resolve `conversationId` for subsequent message fetch and WS send.

#### Scenario: 从他人主页发起私信
- **WHEN** 已登录用户（wxId 非零）点击「发消息」
- **THEN** App SHALL 调用 `POST /conversations` 获取会话 id，再进入聊天页

## MODIFIED Requirements

### Requirement: 消息 Tab SHALL connect WebSocket via gateway-app on same host as apiBaseUrl

Chat WebSocket MUST connect to gateway-app path `/ucg/app/ws/chat` on the same host as `AppEnv.apiBaseUrl`. URL SHALL be derived via `wsUcgChatUrlEffective` (mirroring `wsHistoryUrlEffective`), with optional override via `WS_UCG_CHAT_URL` (`--dart-define`). Connection SHALL follow auth-first-frame pattern similar to `RemoteFeedRepository` with frame format per `ucg-api-contract`. Client MUST NOT connect directly to ucg-service or use a separate UCG WS domain.

#### Scenario: WS 经 gateway 同域
- **WHEN** 已登录用户进入消息 Tab 且 `apiBaseUrl` 为 `https://api.example.com`
- **THEN** Client SHALL 连接 `wss://api.example.com/ucg/app/ws/chat`（或含 path 前缀的等价 URL），且 SHALL NOT 直连 ucg-service 独立域名

#### Scenario: WS URL 可选手动覆盖
- **WHEN** 构建时设置 `--dart-define=WS_UCG_CHAT_URL=wss://custom.example/ucg/app/ws/chat`
- **THEN** `wsUcgChatUrlEffective` SHALL 返回该 override 值

### Requirement: 消息列表 SHALL support WeChat-style swipe actions

Conversation list SHALL show unread red dot on 消息 tab when any unread > 0. List items SHALL support swipe to pin (`PUT /conversations/{id}/pin`) and delete (`DELETE /conversations/{id}`).

#### Scenario: 未读红点
- **WHEN** 存在未读会话
- **THEN** 底部「消息」图标 SHALL 显示红点

#### Scenario: 进入聊天后清除未读
- **WHEN** 用户打开某会话聊天页并加载历史消息（或会话无消息但仍存在未读计数）
- **THEN** App SHALL 调用 `POST /conversations/{id}/read`（可附 `lastMsgId` 为最后一条消息 id）
- **AND** 返回消息列表后该会话 `unreadCount` SHALL 为 0，底部「消息」Tab 红点 SHALL 随之更新

#### Scenario: 聊天中收到新消息保持已读
- **WHEN** 用户正在查看某会话且经 WS 收到对方新消息
- **THEN** App SHALL 再次调用 `POST /conversations/{id}/read`，且 SHALL NOT 使该会话未读角标重新出现

#### Scenario: 置顶会话
- **WHEN** 用户左滑置顶会话
- **THEN** App SHALL 调用 `PUT /conversations/{id}/pin`，且 SHALL NOT 使用 POST

#### Scenario: 1:1 聊天支持多媒体
- **WHEN** 用户在聊天页发送文本/图片/视频
- **THEN** App SHALL 先上传媒体（超限自动压缩），再通过 WS（canonical 帧格式，含 `imageKey`/`videoKey`）发送并在 UI 展示 pending/delivered/failed 状态

### Requirement: Messaging SHALL require login

Opening 消息 tab or chat MUST require logged-in session with non-zero wxId. Device-only `sub=0` SHALL show bind-wechat message.

#### Scenario: 未登录消息
- **WHEN** 未登录用户点击消息 Tab
- **THEN** App SHALL 引导登录

#### Scenario: 设备态无法私信
- **WHEN** `sub=0` 用户打开消息 Tab
- **THEN** App SHALL 展示绑定微信提示，且 SHALL NOT 建立 WS 连接

### Requirement: 聊天窗口 SHALL 展示对方昵称与消息发送者头像

1:1 聊天页顶栏 MUST 左对齐展示对方头像 + 昵称（WeChat 风格）：昵称优先 `ConversationDTO.peerNickname`；空则 `GET /profile/{peerWxId}` 兜底；仍空则「用户 {wxId}」/「用户」。昵称超出顶栏可用宽度时 MUST 尾部省略（`TextOverflow.ellipsis`）。头像与昵称尺寸 MUST 与返回按钮行高一致（约 32dp 圆形头像 + 紧凑标题字号）。顶栏 MUST NOT 展示副标题或营销文案（如「一起聊聊育儿日常」）。每条消息气泡旁 MUST 展示发送者头像：对方消息头像在气泡左侧，自己消息头像在气泡右侧。自己头像来自当前用户 profile；对方头像优先 `peerAvatarCdnUrl`/`peerAvatarKey`，缺失时经 `GET /profile/{peerWxId}` 补全。

#### Scenario: 聊天页标题为对方昵称
- **WHEN** 用户进入与 wxId=123 的会话且 `peerNickname` 为「小明妈妈」
- **THEN** 聊天页顶栏 SHALL 左对齐显示对方头像与「小明妈妈」

#### Scenario: 顶栏昵称过长时省略
- **WHEN** 对方昵称超出顶栏可用宽度
- **THEN** 昵称文本 SHALL 以尾部省略号截断，且头像仍可见

#### Scenario: 聊天顶栏无副标题
- **WHEN** 用户进入 1:1 聊天页
- **THEN** 顶栏 SHALL NOT 显示「一起聊聊育儿日常」或任何副标题文案

#### Scenario: 消息气泡旁展示头像
- **WHEN** 聊天页加载历史或收到新消息
- **THEN** 对方消息左侧、自己消息右侧 SHALL 各显示对应 CircleAvatar；缺图时显示默认人像图标

#### Scenario: 会话缺 peer 资料时补拉 profile
- **WHEN** 从他人主页 `POST /conversations` 进入聊天且响应未带 `peerNickname` 或头像
- **THEN** App SHALL 调用 `GET /profile/{peerWxId}` 补全顶栏头像、昵称与消息气泡旁头像展示

### Requirement: 聊天窗口顶栏 SHALL 提供关注/取关快捷入口

1:1 聊天页顶栏右侧 MUST 展示关注切换按钮（非本人会话）：未关注显示「关注」，已关注显示「已关注」；点击 SHALL 调用 `POST /follow/{peerWxId}` 或 `DELETE /follow/{peerWxId}` 并即时更新按钮文案。进入聊天时 App SHALL 经 `GET /profile/{peerWxId}`（已登录带 Bearer）读取 `isFollowing` 初始化按钮态。关注/取关成功后 SHALL `invalidate` 当前用户 profile 以刷新「我的」`followingCount`。`sub=0` 点击 SHALL 走绑定微信门控；与自己会话 SHALL NOT 展示该按钮。

#### Scenario: 聊天顶栏关注未关注用户
- **WHEN** 已登录用户进入与未关注用户的聊天且 `isFollowing` 为 false
- **THEN** 顶栏右侧 SHALL 显示「关注」；点击后 SHALL 调用 `POST /follow/{wxId}` 并切换为「已关注」

#### Scenario: 聊天顶栏取关已关注用户
- **WHEN** 已登录用户进入与已关注用户的聊天且 `isFollowing` 为 true
- **THEN** 顶栏右侧 SHALL 显示「已关注」；点击后 SHALL 调用 `DELETE /follow/{wxId}` 并切换为「关注」

#### Scenario: 聊天关注后刷新 followingCount
- **WHEN** 用户在聊天顶栏成功关注或取关
- **THEN** App SHALL 刷新「我的」页 `followingCount`（`ucgMyProfileProvider`）

### Requirement: 消息列表 SHALL 在离开聊天或聚焦 Tab 时刷新

会话列表 MUST 在以下时机重新拉取 `GET /conversations` 并同步未读角标：用户从 `UcgChatScreen` 返回（无论从消息 Tab、他人主页私信或广场等入口）；用户切换到消息 Tab。实现 SHALL 使用共享刷新信号（如 `ucgConversationsChangedProvider`）而非仅在消息 Tab 内 `Navigator.push` 的 `.then` 回调。

#### Scenario: 从他人主页私信返回后列表更新
- **WHEN** 用户在广场/他人主页发起私信、聊天后返回并切换到消息 Tab
- **THEN** 会话列表 SHALL 展示最新 `lastPreview`、时间与已读状态，且 SHALL NOT 要求退出 UCG 模块才刷新

#### Scenario: 聚焦消息 Tab 时刷新
- **WHEN** 用户点击底部「消息」Tab
- **THEN** App SHALL 触发会话列表重新拉取

### Requirement: 消息列表 SHALL 展示对方昵称与头像

列表行 MUST 展示对方（非本人）`peerWxId` 对应的昵称与头像：优先 `ConversationDTO.peerNickname` / `peerAvatarUrl`；缺失时 SHALL 调用 `GET /profile/{peerWxId}` 补全（与聊天页 `_ensurePeerProfile` 一致）。`GET /conversations` 响应 MUST 透出 `peerNickname`、`peerAvatarKey`、`peerAvatarUrl`（经 `GetPublicProfile` enrichment）。

#### Scenario: 列表 API 含对方资料
- **WHEN** `GET /conversations` 返回 `peerNickname` 与 `peerAvatarUrl`
- **THEN** 消息列表行 SHALL 展示对应昵称与头像

#### Scenario: 列表缺对方资料时客户端补拉
- **WHEN** 会话项缺 `peerNickname` 或头像
- **THEN** App SHALL 调用 `GET /profile/{peerWxId}` 补全列表行展示
