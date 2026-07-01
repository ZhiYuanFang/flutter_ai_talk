## MODIFIED Requirements

### Requirement: Inline banner when history WebSocket is not ready

The home screen SHALL display a full-width inline banner between the history list region and the bottom input panel **only when** the history WebSocket phase is `gaveUp` and session token refresh is not in flight. 主页**仅当**历史 WebSocket phase 为 **`gaveUp`** 且 **`isRefreshInFlight == false`** 时，**必须**在历史列表与底部输入区之间展示全宽内联错误横幅；其余未就绪态（含初次进入、`disconnected`、`autoReconnecting`、`isRefreshInFlight == true`）**不得**展示任何历史 WS 连接状态横幅。

| 条件 | 横幅 |
|------|------|
| `gaveUp` 且已登录、已绑定、`isRefreshInFlight == false` | **「连接失败，请检查网络后点击重连」**（错误/警示态；可点击重连） |
| `ready` / `disconnected` / `autoReconnecting` / refresh in flight / 未登录 / 未绑定 | （隐藏） |

**`autoReconnecting` 期间 MUST NOT 展示任何历史 WS 连接状态横幅**。未登录或未绑定宝宝时**不得**展示 WS 横幅。

#### Scenario: Banner hidden during auto reconnect

- **WHEN** 用户已登录且已绑定宝宝，且 `historyWsPhase == autoReconnecting`（含 App lifecycle resumed 触发的静默重连）
- **THEN** 历史列表与输入区之间**不得**显示历史 WS 连接状态横幅
- **AND** 历史列表**必须**仍可独立滚动

#### Scenario: Banner hidden on initial home entry before WS connect

- **WHEN** 用户已登录且已绑定宝宝，且刚进入主页，`GatewayBootstrapGate` 尚未完成或历史 WS 尚未调用 `ensureHistoryWebSocketConnected`
- **WHEN** `isHistoryWebSocketReady == false` 且 phase 为 `disconnected`
- **THEN** **不得**展示历史 WS 连接状态横幅

#### Scenario: Banner hidden when disconnected and not gave up

- **WHEN** 用户已登录且已绑定宝宝，且 `isHistoryWebSocketReady == false`，且 phase 为 `disconnected`，且 `isRefreshInFlight == false`
- **THEN** **不得**展示「连接中断，请点击重连」或任何历史 WS 连接状态横幅
- **AND** 底层 **必须**仍可按既有规则自动重连

#### Scenario: Banner hidden during token refresh in flight

- **WHEN** 用户已登录且已绑定宝宝，且 `SessionController.isRefreshInFlight == true`，且历史 WS 尚未就绪
- **THEN** **不得**展示任何历史 WS 连接状态横幅（含「正在恢复连接…」）

#### Scenario: Banner visible on gave up

- **WHEN** 用户已登录且已绑定宝宝，且 phase 为 `gaveUp`，且 `isRefreshInFlight == false`
- **THEN** 横幅文案**必须**为 **「连接失败，请检查网络后点击重连」**
- **AND** 用户点击**必须**可触发重连（reset strike）

#### Scenario: Banner hidden when connected

- **WHEN** 历史 WebSocket 变为已就绪（phase `ready` 且 `isHistoryWebSocketReady == true`）
- **THEN** 内联横幅**必须**隐藏
- **AND** 不得遮挡或缩小历史列表的永久占位（仅移除横幅高度）

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未登录或未绑定宝宝
- **THEN** **不得**展示历史 WS 断开/恢复横幅（避免无意义提示）

### Requirement: 放弃重连横幅与一次性 Snackbar

The home screen SHALL display banner **「连接失败，请检查网络后点击重连」** and a one-time snackbar when history WebSocket phase is `gaveUp` **and** `isRefreshInFlight == false` (and not superseded by autoReconnecting hide rule). 当历史 WebSocket phase 为 **`gaveUp`** 且 **`isRefreshInFlight == false`** 时，主页**必须**展示 **「连接失败，请检查网络后点击重连」** 横幅，并**必须**弹出**一次性** Snackbar（同主题文案）。`isRefreshInFlight == true` 期间**不得**触发 gaveUp 横幅或 Snackbar。进入 `autoReconnecting` 后**必须**隐藏横幅，直至再次进入 `gaveUp`。

#### Scenario: 第三次 strike 后 UI

- **WHEN** 历史 WebSocket 进入 gave-up（连续 3 次 handshake 失败）且当前不在 `autoReconnecting` 且 `isRefreshInFlight == false`
- **THEN** 横幅文案**必须**为「连接失败，请检查网络后点击重连」
- **AND** 必须展示**一次性** Snackbar（同一 gave-up 周期内不得重复 spam）

#### Scenario: gave-up suppressed during refresh

- **WHEN** 历史 WebSocket phase 为 `gaveUp` 但 `isRefreshInFlight == true`
- **THEN** **不得**展示 gaveUp 错误横幅或 Snackbar
- **AND** **不得**展示任何替代 WS 连接状态横幅

#### Scenario: gave-up 横幅仍可点击

- **WHEN** gave-up 横幅可见且用户点击
- **THEN** 客户端**必须** reset strike 并发起重连
- **AND** 重连进行中**不得**展示连接状态横幅
- **AND** 重连成功后就绪时横幅**必须**隐藏

## REMOVED Requirements

### Requirement: Refresh recovery banner visual affordance

**Reason**: 方案 B 取消 refresh 信息态横幅；仅 gaveUp 展示连接失败横幅。

**Migration**: `isRefreshInFlight == true` 期间不再展示任何 WS 连接状态横幅；会话恢复失败由登录 Toast / gaveUp 路径承担。
