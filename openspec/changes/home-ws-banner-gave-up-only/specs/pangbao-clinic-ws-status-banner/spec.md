## MODIFIED Requirements

### Requirement: Inline banner when clinic WebSocket is not ready

The Pangbao clinic screen SHALL display a full-width inline banner below the app bar region and above the conversation list **only when** the clinic WebSocket phase is `gaveUp` and session token refresh is not in flight. 胖宝诊疗页**仅当**诊疗 WebSocket phase 为 **`gaveUp`** 且 **`isRefreshInFlight == false`** 时，**必须**在 AppBar 与对话列表之间展示全宽内联错误横幅；其余未就绪态（含进入页面、`disconnected`、`autoReconnecting`、`isRefreshInFlight == true`）**不得**展示任何诊疗 WS 连接状态横幅。

| 条件 | 横幅 |
|------|------|
| 未同意告知 / 未登录 / 未绑定宝宝 | （隐藏） |
| `gaveUp` 且已登录、已绑定、`isRefreshInFlight == false` | **「连接失败，请检查网络后点击重连」**（错误/警示态；可点击重连） |
| `ready` / `disconnected` / `autoReconnecting` / refresh in flight | （隐藏） |

`autoReconnecting` 期间 **MUST NOT** 展示任何诊疗 WS 连接状态横幅。refresh 明确失败导致未登录时**不得**展示 WS 横幅（由空态与登录 Toast 承担）。

#### Scenario: Banner hidden during auto reconnect

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `clinicWsPhase == autoReconnecting`（含 App lifecycle resumed 触发的静默重连）
- **THEN** AppBar 与对话列表之间**不得**显示诊疗 WS 连接状态横幅
- **AND** 对话列表**必须**仍可独立滚动

#### Scenario: Banner hidden on clinic screen entry before WS ready

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且刚进入胖宝诊疗页，诊疗 WS 尚未就绪
- **WHEN** `isClinicWebSocketReady == false` 且 phase 为 `disconnected`
- **THEN** **不得**展示诊疗 WS 连接状态横幅

#### Scenario: Banner hidden when disconnected and not gave up

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `isClinicWebSocketReady == false`，且 phase 为 `disconnected`，且 `isRefreshInFlight == false`
- **THEN** **不得**展示「连接中断，请点击重连」或任何诊疗 WS 连接状态横幅
- **AND** 底层 **必须**仍可按既有规则自动重连

#### Scenario: Banner hidden during token refresh in flight

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `SessionController.isRefreshInFlight == true`，且诊疗 WS 尚未就绪
- **THEN** **不得**展示任何诊疗 WS 连接状态横幅（含「正在恢复连接…」）

#### Scenario: Banner visible on gave up

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 phase 为 `gaveUp`，且 `isRefreshInFlight == false`
- **THEN** 横幅文案**必须**为 **「连接失败，请检查网络后点击重连」**
- **AND** 用户点击**必须**可触发重连（reset strike）

#### Scenario: Banner hidden when connected

- **WHEN** 诊疗 WebSocket 变为已就绪（`isClinicWebSocketReady == true`）
- **THEN** 内联横幅**必须**隐藏

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未同意告知、未登录或未绑定宝宝
- **THEN** **不得**展示诊疗 WS 断开/恢复横幅

### Requirement: Gave-up banner with one-time snackbar on clinic screen

The Pangbao clinic screen SHALL display the gave-up banner message and a one-time snackbar when clinic WebSocket phase is `gaveUp` and `isRefreshInFlight == false`, unless suppressed by the autoReconnecting hide rule. 当诊疗 WebSocket phase 为 **`gaveUp`** 且 **`isRefreshInFlight == false`** 时，诊疗页**必须**展示 **「连接失败，请检查网络后点击重连」** 横幅，并**必须**弹出**一次性** Snackbar（同主题文案）。`isRefreshInFlight == true` 期间**不得**触发 gaveUp 横幅或 Snackbar。

#### Scenario: Gave-up snackbar after strike exhaustion

- **WHEN** 诊疗 WebSocket 进入 gave-up（连续 handshake 失败达 transport 上限）且当前不在 `autoReconnecting` 且 `isRefreshInFlight == false`
- **THEN** 横幅文案**必须**为「连接失败，请检查网络后点击重连」
- **AND** 必须展示**一次性** Snackbar（同一 gave-up 周期内不得重复 spam）

#### Scenario: Gave-up suppressed during refresh

- **WHEN** 诊疗 WebSocket phase 为 `gaveUp` 但 `isRefreshInFlight == true`
- **THEN** **不得**展示 gaveUp 错误横幅或 Snackbar
- **AND** **不得**展示任何替代 WS 连接状态横幅

#### Scenario: Gave-up banner tap reconnects

- **WHEN** gave-up 横幅可见且用户点击
- **THEN** 客户端**必须** reset strike 并发起 clinic WS 重连
- **AND** 重连进行中**不得**展示连接状态横幅
- **AND** 重连成功后就绪时横幅**必须**隐藏
