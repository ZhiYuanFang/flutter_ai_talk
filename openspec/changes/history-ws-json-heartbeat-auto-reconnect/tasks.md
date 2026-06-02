# Tasks: history-ws-json-heartbeat-auto-reconnect

## 1. 跨仓库联调（go_ai_talk）

- [x] 1.1 在 `go_ai_talk/internal/controller/gateway_app_history_ws.go` read loop 解析 JSON；`type == "ping"` 时回复 `{"type":"pong"}`（独立 PR，契约见 `api-gateway-json-keys` delta）
- [x] 1.2 staging 联调：客户端发 ping 必收 pong；未部署前 Flutter 勿合 main（或 feature flag）

## 2. RemoteFeedRepository 状态机与 strike

- [x] 2.1 定义 `HistoryWsPhase`（`ready` / `autoReconnecting` / `gaveUp` / `disconnected`）与 `historyWsPhaseStream`
- [x] 2.2 实现 attempt 计数：完整周期 connect → auth → auth_ok → first ping → first pong；失败 +1；成功 reset 0；**冷启动首次 connect 计入**（`history-ws-reconnect`）
- [x] 2.3 连续 3 次失败 → gaveUp：停止 ping 与 `_scheduleReconnect`
- [x] 2.4 login / deviceNo 变更 listener：reset strike、exit gaveUp、tearDown 并按新会话重连
- [x] 2.5 App lifecycle：resume 时若 gaveUp **不得**自动 reconnect

## 3. JSON 心跳

- [x] 3.1 `auth_ok` 后发送首次 ping；收到首次 pong 后置 `isHistoryWebSocketReady = true`（**不得** auth_ok  alone 就绪）
- [x] 3.2 就绪后每 25s ping；单次 pong 超时 5s；连续 2 miss → tearDown → 自动重连
- [x] 3.3 出站/入站仅 JSON `{"type":"ping"}` / `{"type":"pong"}`，禁止纯文本 ping

## 4. 自动重连与退避

- [x] 4.1 onError / onDone / heartbeat tearDown 统一 `_scheduleReconnect`（非 gaveUp）
- [x] 4.2 指数退避 1s→30s + jitter 0–500ms；**退避等待不计 attempt**
- [x] 4.3 重连成功路径**不得**调用 `loadHistory` / `tryLoadHistory`（`feed-history-sync`）

## 5. UI：HomeHistoryWsStatusBanner / HomeScreen

- [x] 5.1 订阅 `historyWsPhaseStream`；`autoReconnecting` →「正在重连…」
- [x] 5.2 `gaveUp` →「连接失败，请检查网络后点击重连」+ **一次性** Snackbar
- [x] 5.3 其它未就绪 →「连接中断，请点击重连」；`ready` 隐藏横幅
- [x] 5.4 横幅 tap：reset strike → `reconnectHistoryWebSocket()`；列表仍可滚动

## 6. 回归与校验

- [x] 6.1 手测冷启动：弱网下首次 handshake 失败计 strike，第 3 次 gave-up 停自动重连
- [x] 6.2 手测 gave-up 后 resume 不自动重连；点击横幅 reset 后可再连
- [x] 6.3 手测重连成功 Network 无 `history/api/list`；断线漏事件无自动 list 补偿
- [x] 6.4 运行 `openspec validate history-ws-json-heartbeat-auto-reconnect --strict`

## 7. 重连前 token 刷新

- [x] 7.1 `_beginAttemptOnce` 建连 auth 前调用 `ensureFreshSession()`；成功后再读 accessToken 发 auth
- [x] 7.2 refresh 失败：`signOut`（由 ensureFreshSession 触发）+ 清理 deviceNo/signInChannel + Toast「登录已过期，请重新登录」；**不计** strike
