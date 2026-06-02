# Proposal: history-ws-json-heartbeat-auto-reconnect

## Why

当前历史 WebSocket 在断线后依赖用户手动点击横幅重连，无 JSON 心跳保活、无指数退避自动重连，也无法区分「正在重连」与「已放弃」；`isHistoryWebSocketReady` 在 `auth_ok` 后即置真，无法反映链路真实可用性。断线期间可能丢失推送事件，且若重连成功后仍拉 HTTP list 会与 `feed-history-sync` 主路径冲突。需要在客户端建立 JSON ping/pong 心跳、自动重连与 3-strike 放弃策略，并在服务端（go_ai_talk）补齐 ping 响应契约。

## What Changes

- **JSON 心跳**：客户端周期性发送 `{"type":"ping"}`，期望 `{"type":"pong"}`；**不得**使用语音 ASR 那样的纯文本 ping。就绪条件改为 `auth_ok` **且**收到首次 pong 后才 `isHistoryWebSocketReady = true`。
- **心跳参数**：每 25s 发 ping；单次 pong 超时 5s；连续 2 次未收到 pong → tearDown → 触发重连。
- **自动重连**：任意断开（`onError`、`onDone`、心跳失败）触发指数退避重连（1s→30s + 0–500ms jitter）；退避等待**不计入**尝试次数。
- **3-strike 放弃**：一次尝试 = 完整握手周期（connect → auth → auth_ok → first ping → first pong）；任一步失败 +1 strike；成功就绪 reset 为 0；**冷启动首次 connect 计入 strike**；连续 3 次失败 → GAVE_UP：停止自动重连与 ping。
- **UI 阶段**：`autoReconnecting` 横幅「正在重连…」；`gaveUp` 横幅「连接失败，请检查网络后点击重连」+ 一次性 Snackbar；手动点击横幅 reset strike 并重连。
- **会话重置**：login / deviceNo 变更 reset strike 并 bypass gave-up；App resume **不得**在 gave-up 态自动重试。
- **重连后不同步 list**：重连成功**不得**调用 history list HTTP；严格依赖 WS 增量（`feed-history-sync`）。
- **服务端（跨仓库）**：go_ai_talk `gateway_app_history_ws.go` read loop 须对 JSON ping 回复 pong（本变更在 design 中记录契约，go_ai_talk 需独立变更）。

## Capabilities

### New Capabilities

- `history-ws-reconnect`：历史 WebSocket JSON 心跳、就绪判定、自动重连状态机、3-strike 放弃策略（含冷启动计数）、phase 流与 gave-up 行为。

### Modified Capabilities

- `feed-history-sync`：重连成功不得拉 list；断线期间可能漏收事件的产品语义。
- `home-history-ws-status-banner`：区分 autoReconnecting / gaveUp / 手动重连阶段与文案；gave-up 一次性 Snackbar。
- `api-gateway-json-keys`：历史 WebSocket 出站/入站 JSON ping/pong 键名与 `type` 取值。

## Impact

- **Flutter**：`RemoteFeedRepository`（心跳定时器、重连状态机、strike 计数、phase stream）、`FeedRepository` 接口扩展、`HomeScreen` / `HomeHistoryWsStatusBanner`（阶段文案与 Snackbar）、`isHistoryWebSocketReady` 语义变更。
- **网关契约**：历史 WS 除 auth/auth_ok 外新增 ping/pong JSON 帧；客户端 readiness 依赖首次 pong。
- **跨仓库依赖**：`d:\work\go_ai_talk\internal\controller\gateway_app_history_ws.go` 需在 read loop 中响应 ping（独立 OpenSpec/PR）。
- **基线引用**：`openspec/specs/feed-history-sync`、`home-history-ws-status-banner`、`api-gateway-json-keys`。
