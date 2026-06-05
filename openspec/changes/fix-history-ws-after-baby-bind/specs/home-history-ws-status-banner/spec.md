## REMOVED Requirements

### Requirement: 自动重连中横幅文案

**Reason**: 产品要求自动/后台重连期间不展示连接状态，避免「正在重连…」打扰用户；失败态由 gave-up / disconnected 横幅承担。

**Migration**: 删除 `autoReconnecting` phase 下的全宽横幅展示；保留 phase 状态机供内部重连，UI 仅在非 autoReconnecting 的未就绪态展示横幅。

## MODIFIED Requirements

### Requirement: Inline banner when history WebSocket is not ready

The home screen SHALL display a full-width inline banner between the history list region and the bottom input panel when the history WebSocket is not ready **and** phase is **not** `autoReconnecting`, with text **「连接失败，请检查网络后点击重连」** for `gaveUp` and **「连接中断，请点击重连」** for other applicable not-ready disconnect states. 当历史 WebSocket 未就绪且 phase **不是** `autoReconnecting` 时，主页**必须**在历史记录模块与底部输入模块之间展示全宽内联横幅；`gaveUp` →「连接失败，请检查网络后点击重连」；其它适用未就绪断开态 →「连接中断，请点击重连」。**`autoReconnecting` 期间不得展示任何历史 WS 连接状态横幅**（含「正在重连…」）。

#### Scenario: Banner hidden during auto reconnect

- **WHEN** 用户已登录且已绑定宝宝，且 `historyWsPhase == autoReconnecting`（含 App lifecycle resumed 触发的静默重连）
- **THEN** 历史列表与输入区之间**不得**显示历史 WS 连接状态横幅
- **AND** 历史列表**必须**仍可独立滚动

#### Scenario: Banner visible when disconnected and not auto-reconnecting

- **WHEN** 用户已登录且已绑定宝宝，且 `isHistoryWebSocketReady == false`，且 phase 为 `disconnected` 或 `gaveUp`（非 `autoReconnecting`）
- **THEN** 历史列表与输入区之间**必须**显示 phase 对应横幅
- **AND** AppBar **不得**再展示历史 WebSocket 云图标（重连入口仅保留横幅）

#### Scenario: Banner hidden when connected

- **WHEN** 历史 WebSocket 变为已就绪（phase `ready` 且 `isHistoryWebSocketReady == true`）
- **THEN** 内联横幅**必须**隐藏
- **AND** 不得遮挡或缩小历史列表的永久占位（仅移除横幅高度）

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未登录或未绑定宝宝
- **THEN** **不得**展示历史 WS 断开横幅（避免无意义提示）

### Requirement: Tap banner reconnects history WebSocket

Tapping the inline banner SHALL invoke reconnect, reset the 3-strike counter to 0, and exit gave-up before reconnecting. 用户点击横幅**必须**触发历史 WebSocket 重连；点击时**必须**先将 3-strike 计数 reset 为 **0** 并退出 gave-up，再调用 `reconnectHistoryWebSocket`（或等价）。点击后的 in-flight 重连**不得**因 `autoReconnecting` 而展开「正在重连…」全宽横幅（与「自动重连隐藏横幅」一致）。

#### Scenario: User taps banner to reconnect

- **WHEN** 横幅可见且用户点击横幅任意可点击区域
- **THEN** 客户端**必须** reset strike 并发起历史 WebSocket 重连
- **AND** 重连 attempt 进行中（phase 为 `autoReconnecting`）**不得**展示连接状态横幅
- **AND** 连接并就绪成功后横幅**必须**隐藏

#### Scenario: Reconnect does not block history scroll

- **WHEN** 横幅展示中
- **THEN** 历史列表区域**必须**仍可独立滚动
- **AND** 横幅**不得**覆盖在历史列表之上（必须为布局兄弟节点，位于列表下方）

### Requirement: 放弃重连横幅与一次性 Snackbar

The home screen SHALL display banner **「连接失败，请检查网络后点击重连」** and a one-time snackbar when history WebSocket phase is `gaveUp` (and not superseded by autoReconnecting hide rule). 当历史 WebSocket phase 为 **`gaveUp`** 时，主页**必须**展示 **「连接失败，请检查网络后点击重连」** 横幅，并**必须**弹出**一次性** Snackbar 提示（同主题文案）。进入 `autoReconnecting` 后**必须**按「自动重连隐藏横幅」隐藏，直至再次进入 gaveUp 或 disconnected。

#### Scenario: 第三次 strike 后 UI

- **WHEN** 历史 WebSocket 进入 gave-up（连续 3 次 handshake 失败）且当前不在 `autoReconnecting`
- **THEN** 横幅文案**必须**为「连接失败，请检查网络后点击重连」
- **AND** 必须展示**一次性** Snackbar（同一 gave-up 周期内不得重复 spam）

#### Scenario: gave-up 横幅仍可点击

- **WHEN** gave-up 横幅可见且用户点击
- **THEN** 客户端**必须** reset strike 并发起重连
- **AND** 重连进行中**不得**展示「正在重连…」横幅
- **AND** 重连成功后就绪时横幅**必须**隐藏
