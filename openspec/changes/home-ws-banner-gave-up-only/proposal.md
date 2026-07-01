## Why

喂养主页进入时，历史 WebSocket  intentionally 延迟至 `GatewayBootstrapGate` 完成后再建连；此窗口内客户端状态为 `disconnected + !ready`，现有规则会立即展示「连接中断，请点击重连」横幅，给用户造成「一进 App 就断线」的错误印象，显得不专业。方案 B 采用最简策略：仅在 transport 3-strike 进入 `gaveUp`（实在连不上）时才展示连接失败横幅，其余阶段（含初次进入、自动重连、token refresh、普通 disconnected）一律静默，由底层 `ResilientWebSocketClient` 自动恢复。

## What Changes

- **BREAKING（用户可见）**：移除主页历史 WS 在 `disconnected` 与 `isRefreshInFlight` 阶段的内联连接状态横幅；仅 `gaveUp` 且 `isRefreshInFlight == false` 时展示错误横幅。
- **BREAKING（用户可见）**：胖宝诊疗页 WS 横幅规则与主页对齐（仅 `gaveUp` 展示）。
- 保留：`gaveUp` 时的一次性 Snackbar、横幅点击 reset strike 并重连、`autoReconnecting` 期间隐藏横幅。
- 保留：发送/提问前 WS 未就绪时的 Toast 提示（`_ensureHistoryWsForSend` / 诊疗页等价逻辑），作为非横幅的轻量反馈。
- 不改动：`ResilientWebSocketClient` 重连语义、后端 `/device/app/ws/history` 协议。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-history-ws-status-banner`：横幅可见性从「分级（refresh / disconnected / gaveUp）」收窄为「仅 gaveUp」；删除 disconnected 与 refresh 信息态横幅相关 Requirement/Scenario。
- `pangbao-clinic-ws-status-banner`：与主页对齐，删除 disconnected 与 refresh 信息态横幅相关 Requirement/Scenario。

## Impact

- **客户端**：`app/lib/ui/home_screen.dart`、`app/lib/ui/pangbao_ai_screen.dart` 中 `showWsBanner` / 等价可见性逻辑；`home_history_ws_status_banner.dart` 文案常量可保留（gaveUp 仍用）。
- **规格**：`openspec/changes/home-ws-banner-gave-up-only/specs/**` delta；归档时合并进下一版基线。
- **后端 / 传输层**：无变更。
