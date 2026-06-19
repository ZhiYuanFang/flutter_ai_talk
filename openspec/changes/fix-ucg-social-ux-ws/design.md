## Context

当前 Flutter 客户端存在两类问题：**交互/视觉**（compose 闪屏、相册全屏刷新、聊天表情、额度遮挡）与 **连接可靠性**（UCG 聊天 WS 仅在 `UcgShell`/`UcgChatScreen` 内 `setWsConnectionDesired(true)`，无登录级长连、无 ping/pong、固定 3s 重连）。喂养历史 WS 已在 `RemoteFeedRepository` 实现完整韧性（`history-ws-reconnect` 基线），UCG 侧 `UcgRepository` 为精简实现。

后端 `go_ai_talk` 已约定：发送帧含 `clientMsgId`；服务端向发送方先发 `message_ack`（顶层 `clientMsgId`），再向双方推送 `message_delivered`（`message.clientMsgId` + 服务端 `id`）。Flutter 端乐观消息使用 `local-*` id，WS 发送使用 `client-*`，且未解析 `clientMsgId` → 重复气泡。

约束：遵循 `v2.0.2` 基线；拍摄界面文案已中文，不改动；不新增测试文件（仓库规则）。

## Goals / Non-Goals

**Goals:**

- 抽取 `ResilientWebSocketClient`，历史 WS 与 UCG WS 共用传输语义（对齐 `history-ws-reconnect`）。
- 登录且 wxId 已绑定后，UCG 聊天 WS 在 App 前台保持 desired 连接（含用户停留喂养页时）。
- 聊天 `clientMsgId` 端到端关联，消除重复消息；处理 `audit_failed`。
- 修复聊天表情、compose 闪屏、相册局部刷新、额度布局、广场入口未读角标。

**Non-Goals:**

- 拍摄/系统相机 UI 本地化。
- 后端协议变更。
- 历史 WS 用户可见行为变更（仅内部重构到共享客户端）。
- 自定义贴纸、新未读推送类型。

## Decisions

### 1. 共享 WS 客户端位置与 API

在 `app/lib/network/resilient_websocket_client.dart` 新增：

- `WsConnectionPhase`：`disconnected | autoReconnecting | ready | gaveUp`（与 `HistoryWsPhase` 对齐，历史侧可 type-alias 或逐步迁移枚举名）。
- `WsConnectionConfig`：每通道注入 `url`、`shouldConnect()`、`prepareToken()`、`buildAuthFrame(token)`、握手是否要求首次 pong（历史 `true`，UCG 建议 `true` 以统一死连接检测）。
- `ResilientWebSocketClient`：管理 connect 代际、auth 超时、ping 25s / pong 8s、miss 2 次 tearDown、指数退避 1s→30s + jitter、3-strike gaveUp、`onAppLifecycleResumed()`、`setConnectionDesired(bool)`。

`RemoteFeedRepository` 与 `UcgRepository` 保留 **业务帧路由**（history record merge vs chat message / notification），将 `_ws`、定时器、重连逻辑下沉到 client。

**备选**：仅复制粘贴到 UCG → 拒绝，维护双份逻辑。

### 2. UCG WS 登录即 desired

在 `ucgRepositoryProvider`（或 App 级 listener）监听 `sessionProvider.isLoggedIn` 与 `ucgCurrentUserIdProvider`：登录且 `isUcgWxAccountBound` 时 `setConnectionDesired(true)`；登出 `false`。

`UcgShell` / `UcgChatScreen` 不再各自独立「开启 WS」，改为 **引用计数或幂等 desired**（共享 client 内 `desiredCount` 或单一全局 desired，推荐单一「登录即 desired」，`UcgShell.dispose` 不得 tearDown 全局连接）。

`prepareToken` 复用历史侧 `ensureFreshSession()` + access token getter；UCG auth 帧保持 `{type:auth, token}`（与 gateway 一致，不用 `accessToken` 字段名）。

### 3. 聊天消息去重

- 发送路径生成单一 `clientMsgId`（如 `client-${ms}`），乐观行 **以 `clientMsgId` 为键**（扩展 `UcgChatMessage` 字段）。
- `UcgRepository._onWsMessage` 新增：`message_ack` → 可选快速更新状态；`message_delivered` → 解析 `message.clientMsgId`，upsert 列表；`audit_failed` → 按顶层 `clientMsgId` 标失败。
- `UcgChatScreen._listenWs`：**禁止**盲 `add`；实现 `_upsertMessage(UcgChatMessage)`：先匹配 `clientMsgId`，再匹配 `id`。
- 移除发送完成后仅凭 HTTP 返回即 `_markMessage(delivered)` 的路径，改由 WS 事件驱动（或 ack 作中间态）。

### 4. 聊天表情交互

- `UcgPageComposerChrome` 表情按钮：`binding == null` 时先对 controller attach + requestFocus（不 show IME）再 `requestEmoji()`。
- `keyboard_input_bridge.dart`：`shouldSuppressOutsideDismissFor` 在 `overlayConfig.showEmoji == false`（`ucg.chat`）且 `_target == emoji` 时返回 **false**，允许 `KeyboardDismissScope` 调用 `collapseInputChrome()`。

### 5. Compose 上传完成防闪

- `UcgComposeMediaPreview`：当同时有 `localPath` 与 `objectKey` 时 **继续显示本地图**，后台 `precacheImage` 成功后再切换网络（或淡入）。
- `ValueKey` 稳定为 `cell.id`  alone。
- `onUpdated` 回调改为 slot 级 `Listenable`（`UcgComposeMediaSlot` 继承/混入 `ChangeNotifier`）或仅 `markNeedsBuild` 对应 grid cell，避免整页 `setState`。

### 6. 相册局部刷新

- `UcgAlbumPickerScreen`：移除外层 `ListenableBuilder` 包裹整个 `GridView`。
- `_AssetCell` 改为 `StatefulWidget`，缩略图 `Future` 在 `initState` 缓存；选择角标用局部 `ListenableBuilder(listenable: selection)` 仅重建 badge 层。

### 7. AI 额度与广场角标

- `HomeScreen` 语音 stack：将 `AiQuotaRemainingHint` 置于语音球 **下方**（`Column` 或 `Positioned` bottom offset = orb 半径 + 间距），使用 `BackdropFilter` + 半透明胶囊（复用 `AppGlassOverlay` 样式 token）。
- `UcgEnterSquareTab`：`Consumer` watch `ucgUnreadCountProvider > 0`，在图标左上角绘制红点（与 `UcgBottomDock` badge 视觉一致）。

未读数继续由 WS `comment_notification` + HTTP 校准（`_syncShellUnreadBadge`），登录后 WS 长连保证实时性。

## Risks / Trade-offs

- **[Risk] 登录即 UCG WS 增加耗电/流量** → 与历史 WS 同等 ping 间隔；仅 wxId 已绑定用户启用；后台可后续加 App 后台暂停（本次不实现）。
- **[Risk] 历史 WS 重构引入回归** → 先让 UCG 接入共享 client，历史侧小步迁移并保持 `history-ws-reconnect` 行为测试清单。
- **[Risk] compose 本地/网络双源预览短暂不一致** → precache 失败时永久保留本地预览直至用户离开页。
- **[Risk] `clientMsgId` 碰撞** → 使用毫秒时间戳 + 可选随机后缀；服务端以 conversation 维度去重。

## Migration Plan

1. 落地 `ResilientWebSocketClient` + 单元逻辑自测（手工）。
2. UCG repository 切换至共享 client；provider 加登录 listener。
3. 聊天去重 + 表情 + compose + 相册 + UI 额度/角标（可并行子任务）。
4. 历史 repository 迁移共享 client（保持对外 API 不变）。
5. 手工验证：登录停留喂养页收私信、发消息不重复、编辑动态加图、相册点选、表情内外点击、额度位置。

回滚：保留旧 `UcgRepository` WS 代码路径 feature flag（可选，默认直接替换）。

## Open Questions

- gaveUp 态 UCG 是否展示与历史相同的用户提示条？**建议**：首版静默指数退避，gaveUp 后消息 Tab 展示轻提示 + 点击重试（与历史对齐）。
- App 进入后台是否暂停 UCG WS？**建议**：首版与历史一致，仅 `resumed` 时补偿重连，不做 background disconnect。
