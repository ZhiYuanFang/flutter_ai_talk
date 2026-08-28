## Why

冷启动进预测后，历史 WebSocket 偶发**从未 `ready`**；用户再进喂养页也不会补连（主壳已独占 `watchLatest`/`ensure`，喂养页不再建连）。根因是激活一次后进入 **`gaveUp`** 或 **precondition paused** 等终态后缺少静默自愈：`ensure` 对 `gaveUp` 无效、按钮/预测模式无重连入口、login/壳激活未 resetStrike、deviceNo 边沿未唤醒 history reconnect。产品选择**静默自愈**，避免依赖用户点横幅。

## What Changes

- 主壳会话期间，在已登录、gateway bootstrap 完成、`connectionDesired` 且已 `watchLatest` 订阅的前提下，若历史 WS **长期未 `ready`**（含 `gaveUp`、`disconnected`、precondition paused），客户端 MUST **静默** resetStrike（必要时）并 reconnect / 再 ensure，**不得**依赖喂养页 mount 或用户点击。
- **BREAKING（相对 v2.1.0「App resume 不得在 gave-up 自动重试」）**：主壳会话活跃时，App resume 与壳层自愈路径 MUST 允许对 `gaveUp` 做**有限次数**的静默重试；耗尽后仍停留 `gaveUp`，既有语音模式横幅手动重连仍可用。
- 游客→登录 / 主壳 `_activateHistoryWsSession`（或等价）路径 MUST 在 ensure 前 **resetStrike**，避免同进程残留 `gaveUp` 导致 ensure 空转。
- history 通道 MUST 在本地 `deviceNo` 从空变为非空（及绑定/切换后已有显式 reconnect 之外的缺口）时触发 `reconnect(resetStrike: true)`，并清 precondition pause。
- App lifecycle resume 对 history WS 的编排 MUST 上移到主壳（或与壳会话等价的单一 owner），不得仅依赖喂养 `HomeScreen` 是否曾 mount。
- 保持：仍经 `ResilientWebSocketClient`；provider create 不得自动建连；登出 tearDown；按钮模式不强制展示 gaveUp 横幅（自愈优先静默）。

## Capabilities

### New Capabilities

- `history-ws-silent-heal`：主壳会话下历史 WS 未就绪时的静默自愈（含有限次 gaveUp 重试、激活 resetStrike、deviceNo 唤醒、壳层 resume）。

### Modified Capabilities

- `history-ws-reconnect`：放宽「resume 不得在 gave-up 自动重试」为「主壳会话内有限次静默自愈可 resetStrike 再连」；明确壳激活路径 resetStrike；deviceNo 变更须能唤醒 reconnect（不仅绑定页显式调用）。

## Impact

- 代码：`ucg_home_shell.dart`（激活 resetStrike、自愈/resume）、`repositories.dart` / `ws_session_binding.dart`（history `watchDeviceNo`）、`resilient_websocket_client.dart`（若需暴露 precondition 恢复或 gaveUp 有限自愈钩子）、`home_screen.dart`（resume 去重或委托壳层）、`pangbao_transport_release.dart`（登出 reset 自愈计数）。
- 行为：冷启动偶发握手失败后，无需进喂养/点横幅即可在短时内恢复 `ready`；自愈耗尽后语义回落现网 gaveUp。
- 约束：遵守副作用治理（single-flight、熔断/有限次）；Debug 经 `AppDebugLog.wsTransport`；不新建 `**/test/**`。
