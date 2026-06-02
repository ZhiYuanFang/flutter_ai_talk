## Context

- **现状**：`RemoteFeedRepository` 在 `watchLatest()` 订阅时 `_ensureWs()` 建连，首帧 `auth` 后收到 `auth_ok` 即设 `isHistoryWebSocketReady = true`；断线后仅暴露 `reconnectHistoryWebSocket()` 供 UI 手动触发，无心跳、无退避、无放弃策略。`HomeHistoryWsStatusBanner` 在 `!isHistoryWebSocketReady` 时固定展示「连接中断，请点击重连」。
- **基线**：`openspec/specs/feed-history-sync` 禁止发消息后 list，但尚未规定重连成功后的 list 行为；`home-history-ws-status-banner` 仅区分就绪/未就绪；`api-gateway-json-keys` 覆盖 auth 帧 camelCase，未覆盖 ping/pong。
- **服务端**：`go_ai_talk/internal/controller/gateway_app_history_ws.go` 在 `auth_ok` 后 read loop 仅空读消息，不解析 ping，无法回复 pong。
- **约束**：历史 WS 与语音 ASR WS 独立；心跳必须为 JSON，**不得**沿用 ASR 纯文本 ping。重连成功后严格走 WS 增量，不得 HTTP list。

## Goals / Non-Goals

**Goals:**

- 在 `RemoteFeedRepository` 内实现历史 WS 状态机：connecting → authenticated → heartbeatReady → connected；断开时 autoReconnecting；3 次连续失败 → gaveUp。
- JSON 心跳：25s 周期 ping，5s pong 超时，连续 2 次 miss → tearDown → 重连（计 1 strike）。
- 指数退避自动重连：1s 起，上限 30s，+jitter 0–500ms；退避等待不计 attempt。
- 一次 attempt = connect → auth → auth_ok → first ping → first pong；**冷启动首次 connect 同样计入 strike**。
- 成功就绪 reset strike；login/deviceNo 变更 reset strike 并 bypass gave-up。
- 暴露 `historyWsPhaseStream`（或等价）供 `HomeScreen` / banner 展示「正在重连…」「连接失败…」。
- 文档化 go_ai_talk 侧 ping/pong 契约（跨仓库依赖）。

**Non-Goals:**

- 改造语音 ASR WebSocket 心跳或重连。
- 断线期间漏事件的 HTTP 补偿 list（产品接受可能漏收，见 `feed-history-sync` delta）。
- 在 gave-up 态由 App resume 自动重试。
- 在本 flutter 变更中实现 go_ai_talk 代码（仅文档契约与联调任务）。

## Decisions

### 1. 就绪判定：auth_ok + 首次 pong

- **决策**：`isHistoryWebSocketReady` 仅在收到 `auth_ok` **且**完成首次 ping/pong 握手后置 `true`；`auth_ok`  alone 不足。
- **理由**：检测链路双向可用，避免「已 auth 但 NAT/代理已断」的假象。
- **备选**：仅 auth_ok（现行为）——无法检测半开连接。

### 2. JSON 心跳协议

- **决策**：客户端发送 `{"type":"ping"}`，期望 `{"type":"pong"}`；键名 camelCase，与 `api-gateway-json-keys` 一致。
- **参数**：周期 25s；单次等待 5s；连续 2 次未收到 pong → `_tearDownWs()` → 触发重连流程（该重连周期若 handshake 失败计 +1 strike）。
- **理由**：与网关 JSON 风格统一；参数与探索结论一致。
- **备选**：WebSocket 协议层 ping frame——Dart `web_socket_channel` 与服务端 Go 读 loop 当前按 JSON 文本帧处理，改协议层成本高。

### 3. 状态机与 phase 流（RemoteFeedRepository）

- **决策**：新增 `HistoryWsPhase` 枚举（建议值）：
  - `disconnected`：未就绪且未在自动重连（如 gave-up 或初始未启动）
  - `autoReconnecting`：退避后正在 attempt
  - `gaveUp`：3-strike 已达，停止 ping 与自动重连
  - `ready`：心跳就绪，对应 `isHistoryWebSocketReady == true`
- **strike 计数**：独立 `_consecutiveFailedAttempts`；attempt 失败 +1；handshake 成功（ready）→ 0；banner 手动 tap / login / deviceNo 变更 → 0 并退出 gaveUp。
- **冷启动**：App 启动后 `watchLatest()` 触发的**第一次** `_ensureWs()` 完整 handshake 失败同样 +1 strike（用户已确认）。
- **退避**：`delay = min(1000 * 2^attemptIndex, 30000) + random(0..500)` ms；**等待 delay 期间不算 attempt**；delay 结束后开始下一次 handshake 计新 attempt。

### 4. 自动重连触发

- **决策**：以下事件统一走 `_scheduleReconnect()`（若未 gaveUp）：`onError`、`onDone`、心跳 double-miss tearDown、handshake 任一步失败。
- **gaveUp 后**：停止 ping timer、停止 `_scheduleReconnect`；仅 manual reconnect（banner tap）或 login/deviceNo 变更可重启。

### 5. 重连成功不得 list

- **决策**：handshake 成功进入 `ready` 时**不得**调用 `loadHistory()` / `tryLoadHistory()`；继续依赖 WS `create`/`update`/`delete` 增量。
- **理由**：与 `feed-history-sync` 主路径一致；避免重连风暴叠加 list 负载。
- ** trade-off**：断线期间事件永久缺失直至用户下拉刷新或其他显式 list 路径（若有）。

### 6. UI 映射（HomeHistoryWsStatusBanner）

- **决策**：
  - `autoReconnecting` → 横幅「正在重连…」，可展示 indeterminate progress；不可重复 spam 点击（可选 debounce）。
  - `gaveUp` → 「连接失败，请检查网络后点击重连」+ **一次性** Snackbar（同文案或简短说明）；点击横幅 → reset strike + `reconnectHistoryWebSocket()`。
  - `disconnected` 且非 gaveUp、非 autoReconnecting（如首次断线瞬态）→ 可仍用「连接中断，请点击重连」或并入 autoReconnecting（实现时二选一，建议尽快进入 autoReconnecting）。
- **App resume**：生命周期回调**不得**在 `gaveUp` 态自动调用 reconnect。

### 7. 跨仓库：go_ai_talk ping 响应

- **决策**：在 `gateway_app_history_ws.go` read loop 中解析 JSON；若 `type == "ping"` 则 `WriteJSON({"type":"pong"})`；其它未知 type 可忽略或记录 debug。
- **路径**：`d:\work\go_ai_talk\internal\controller\gateway_app_history_ws.go`
- **说明**：go_ai_talk 需独立 PR/OpenSpec；flutter 变更 tasks 含联调项，design 记录契约供后端对齐。

### 8. 重连前 token 刷新

- **决策**：每次 `_beginAttemptOnce` 在 connect/auth 前调用 `SessionController.ensureFreshSession()`；成功后再读 `accessToken` 发 auth；失败则 `signOut` + 清理 deviceNo/signInChannel + Toast，**不计 strike**。
- **理由**：与 HTTP `authorizedApiClient` 401 refresh 语义对齐；避免 access 过期导致 WS auth 连续失败快速 gave-up。
- **备选**：仅在 WS 收到 auth error 后 refresh——滞后，仍消耗 strike。

## Risks / Trade-offs

- **[Risk] 旧网关未发 pong** → 客户端永远无法 ready、快速耗尽 3 strike → gaveUp。**Mitigation**：后端同步上线 ping 响应；tasks 中先联调 staging。
- **[Risk] 断线漏事件** → 列表与服务端不一致。**Mitigation**：规格明确产品语义；保留首屏/用户主动 list 路径；不在重连成功自动 list。
- **[Risk] 冷启动计入 strike 导致弱网用户快速 gaveUp** → 3 次完整 handshake 失败才放弃，且 manual tap 可 reset。**Mitigation**：文案引导检查网络；login 切换可 reset。
- **[Risk] auth_ok 后至 first pong 窗口内 sendCommand 被拒** → 略增延迟。**Mitigation**：就绪流已有；发消息前校验保持不变。

## Migration Plan

1. **后端先行或同发**：go_ai_talk 部署 ping/pong 响应。
2. **Flutter 发布**：含状态机与 banner 文案变更；`isHistoryWebSocketReady` 语义变严，依赖 pong。
3. **回滚**：恢复 auth_ok 即 ready、移除 heartbeat/自动重连/gaveUp；banner 回退旧文案。
4. **监控**：日志 strike 计数、phase 转换、heartbeat miss（debug 级）。

## Open Questions

- `disconnected` 与 `autoReconnecting` 是否在 UI 上合并为单一「正在重连…」（减少文案闪烁）——建议 v1 合并展示。
- gave-up Snackbar 是否使用 `app-transient-top-hint` 现有组件——实现时复用项目 transient hint 规范。
