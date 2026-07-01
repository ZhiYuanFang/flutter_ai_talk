## Context

主页与胖宝诊疗页共用 `HomeHistoryWsStatusBanner` 组件，可见性由 `home_screen.dart` / `pangbao_ai_screen.dart` 根据 `HistoryWsPhase`、`isHistoryWebSocketReady` / `isClinicWebSocketReady`、`SessionController.isRefreshInFlight` 组合判定。

当前 v2.0.3 基线要求：`disconnected`、`isRefreshInFlight`、`gaveUp` 均可能展示横幅。由于历史 WS 在 `GatewayBootstrapGate.ensureLoggedInComplete`（及 iOS 额外 2s 延迟）之后才调用 `ensureHistoryWebSocketConnected()`，用户进入主页时会长时间处于 `disconnected + !ready`，误触发「连接中断」横幅。

底层 `ResilientWebSocketClient` 已具备 `autoReconnecting` 隐藏规则、指数退避与 3-strike `gaveUp`；方案 B 不再用横幅覆盖中间态，仅在最终放弃时提示用户。

## Goals / Non-Goals

**Goals:**

- 主页与诊疗页 WS 连接横幅**仅在 `gaveUp` 且 `isRefreshInFlight == false`** 时可见。
- 保留 gaveUp 一次性 Snackbar、横幅点击 reset strike + reconnect、autoReconnecting 期间隐藏。
- 最小 diff：仅改 UI 可见性布尔表达式，不引入新 phase、不改 transport。

**Non-Goals:**

- 不提前历史 WS 建连时机（不改动 `GatewayBootstrapGate` / iOS delay）。
- 不新增 `connecting` / `pending` phase。
- 不改动 `_ensureHistoryWsForSend` 等发送前 Toast。
- 不改动后端 gateway WS 或 `ResilientWebSocketClient` 重连策略。

## Decisions

### 1. 可见性条件收窄为 gaveUp-only

**选择**：`showWsBanner = loggedIn && !needsDeviceBind && phase == gaveUp && !isRefreshInFlight`（诊疗页加 consent 门控）。

**理由**：方案 B 定义即「实在连不上才显示」；实现最简单，与 explore 结论一致。

**备选（未采用）**：

- 方案 A（bootstrap 宽限期 + 曾 ready 后 disconnected 仍显示）：覆盖面更广但规则更复杂。
- 仅主页改、诊疗页不动：两页体验不一致，用户困惑。

### 2. 删除 refresh 信息态横幅

**选择**：`isRefreshInFlight == true` 时也不展示「正在恢复连接…」横幅。

**理由**：方案 B 要求除 gaveUp 外一律静默；token refresh 期间 transport 通常自行重连，且 refresh 失败会走登录 Toast / 空态，无需第二条横幅通道。

**保留**：gaveUp 在 refresh 期间仍 suppressed（与现 spec 一致），refresh 结束后再展示 gaveUp 横幅。

### 3. 文案与组件复用

**选择**：继续复用 `kHomeHistoryWsGaveUpMessage` 与 `HomeHistoryWsStatusBanner`；`kHomeHistoryWsDisconnectMessage` / `kHomeHistoryWsRefreshRecoveryMessage` 可保留常量（供 Toast 或未来使用），但横幅不再引用。

### 4. 两页逻辑对称

**选择**：`home_screen.dart` 与 `pangbao_ai_screen.dart` 使用相同 gaveUp-only 谓词（各自 gate：`needsDeviceBind` vs consent/login/bind）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 中途断线（未达 gaveUp）用户无横幅感知 | 自动重连静默进行；用户尝试发送时仍有 Toast「历史实时连接未就绪…」 |
| gaveUp 前可能等待数秒（3-strike + 退避） | 与现 transport 行为一致；gaveUp 后 Snackbar + 横幅明确提示 |
| 删除 refresh 横幅后 refresh 长耗时无 inline 反馈 | refresh 通常 < 数秒；极端情况依赖 gaveUp 或登录过期 Toast |

## Migration Plan

1. 合并 delta spec → 实现 UI 条件变更 → 手工验证冷启动 / 断网 / gaveUp / 点击重连。
2. 无服务端部署依赖；App 发版即可。
3. 回滚：恢复旧 `showWs*` 布尔组合。

## Open Questions

（无 — 方案 B 已在 explore 阶段确认。）
