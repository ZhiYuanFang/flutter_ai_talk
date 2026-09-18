## Context

UCG chat 使用 `ResilientWebSocketClient`（`UcgRepository`），会话门闸 `_ucgHomeSessionActive` 同时控制 **desired** 与 **`ucgUnreadSyncProvider` 是否真正跑 HTTP**。当前 `activateUcgHomeSession` 仅从喂养页 `mountUcgHomeTransportsIfEligible` 调用，而历史 WS 已在 `UcgHomeShell` 激活；主壳 resume 已调 UCG `onAppLifecycleResumed`，但首次 desired 仍绑喂养页。

未读：`ucgUnreadCountProvider` 由 WS 乐观 +1 与 HTTP（会话第 1 页 unread 之和 + 互动 `unreadCount`）覆盖；消息 Tab / 悬浮球 / `FlutterAppBadger` 只读该整数。列表行未读是另一份 HTTP UI 状态。single-flight 在 in-flight 期间后来的调用只 await 不重跑，已读后易残留虚高。

消息页无 chat WS phase UI；历史页已有 `HomeHistoryWsStatusBanner` 可对标。重试策略（strike / gaveUp / resume）本变更不改。

主题约定：未读点固定红须经 `AppColor` 语义入口（新增如 `unreadDot`），禁止业务内联散落 hex，也禁止继续用 `primary`。

## Goals / Non-Goals

**Goals:**

- 主壳登录门闸完成后激活 UCG 会话（HTTP 首轮校准 + desired）；喂养页不再 mount UCG 传输。
- 消息 Tab 展示连接中 / 连接失败；gaveUp 可点既有 reconnect（resetStrike）；不改传输退避。
- HTTP 覆盖在刷新、进消息 Tab、离开聊天、互动已读后可靠写入；single-flight 结束后补跑未决请求。
- 消息 Tab 与广场悬浮球未读点固定红。

**Non-Goals:**

- 不改 `ResilientWebSocketClient` strike 次数、退避曲线、gaveUp 语义。
- 不新增 UCG SilentHeal；不改厂商推送 register。
- 不解决 `message` + `message_delivered` 双帧 +2（可后续）；不改会话行数字胶囊颜色。
- 不新建 `**/test/**`。

## Decisions

### D1. 激活点：`UcgHomeShell` 对齐历史 WS

在主壳 `GatewayBootstrapGate` / 登录完成后调用 `activateUcgHomeSession`（与 `_activateHistoryWsSessionIfNeeded` 同级，可略错开避免同 host 挤槽）。从 `HomeScreen._startHomePangbaoTransportsAfterGate` **移除** `mountUcgHomeTransportsIfEligible`。

`PangbaoHomeTransportGate` 已表示主壳挂载，继续作为 `requireHomeMounted` 依据。

备选（未选）：仅在进 UCG 页激活——无法支撑预测页悬浮球未读与后台收信。

### D2. 连接态 UI：只映射 phase，不改策略

消息 Tab 顶（列表上方）横条：

| phase / 条件 | UI |
|--------------|-----|
| `ready` | 无横条 |
| `autoReconnecting` | 连接中（info，不可点或点无副作用） |
| `disconnected` 且 session active 且 desired | 并入连接中 |
| `gaveUp` | 连接失败 + 点击 → `reconnectChatWebSocket(resetStrike: true)` |
| 未登录 / 无 wxId / session 未 active | 不展示（避免误报） |

对标 `HomeHistoryWsStatusBanner` 交互与文案风格；可复用或抽薄包装，不复制第二套传输逻辑。

activate 首次 wait 失败仍 `desired=false`（现行为）——本变更不改；用户点重连会再次 desired+resetStrike。

### D3. 未读权威：HTTP 覆盖 + 未决补跑

- 保持 WS 乐观 +1（基线方案 A）。
- `ucgUnreadSyncProvider`：主壳会话 active 后可用；主动路径（消息下拉刷新、进消息 Tab、聊天/互动已读）必须调用且真正覆盖。
- single-flight：若调用时已有 in-flight，await 结束后若期间又有 sync 请求（脏标记），**再跑一轮**——满足「合并并发」同时避免「已读落在 in-flight 之后丢覆盖」。
- 聊天页：每次成功 `markConversationRead` 后都应触发校准（去掉「每会话只清一次」的 `_unreadBadgeCleared` 限制，或等价保证多次已读仍 HTTP 覆盖）。

### D4. 固定红：`AppColor.unreadDot`

新增语义色（常量红，如既有 `0xFFE53935`），消息 Tab `_DockItem` 与 `UcgSquareEdgeDock` 未读点使用之；注释标明「未读指示不跟主题 primary」。

### D5. 与 `ucg-shell-navigation` 旧「进出 UcgShell 才 desired」对齐

基线曾写「进 UcgShell desired=true / 离开 false」。现行与目标均为 **主壳会话** 持有 desired（预测页亦可收信）。本变更 MODIFIED 该 Requirement：离开 UCG 子页回到预测 **不得** 单独断 chat WS；仅主壳 release / 登出 deactivate。

## Risks / Trade-offs

- [主壳与历史 WS 同时建连挤槽] → 可沿用 iOS 历史延迟错峰；UCG activate 可 `unawaited` 不阻塞首帧。
- [横条在 autoReconnecting 打扰] → 文案短、高度固定；ready 即消失。
- [补跑单飞增加偶发双请求] → 仅脏标记时第二轮；符合副作用 HTTP 治理精神。
- [activate 失败 desired=false 与「连接中」展示] → 失败进 gaveUp/disconnected 后横条可见；点重连恢复。

## Migration Plan

纯客户端行为；无服务端迁移。发布后冷启主壳即激活；旧「必须先滑喂养」依赖消失。

## Open Questions

无（探索已拍板：重试策略不动；连接中+失败都展示；与主壳建连、未读、固定红一起改）。
