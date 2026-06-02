# home-history-ws-status-banner 变更规格

基线：`openspec/specs/home-history-ws-status-banner/spec.md`

## ADDED Requirements

### Requirement: 自动重连中横幅文案

The home screen SHALL display banner text **「正在重连…」** when history WebSocket phase is `autoReconnecting`. 当历史 WebSocket phase 为 **`autoReconnecting`** 时，主页**必须**展示横幅文案 **「正在重连…」**。

#### Scenario: autoReconnecting 可见

- **WHEN** 用户已登录且已绑定宝宝，且 `historyWsPhase == autoReconnecting`
- **THEN** 历史列表与输入区之间**必须**显示「正在重连…」横幅
- **AND** 历史列表**必须**仍可独立滚动

### Requirement: 放弃重连横幅与一次性 Snackbar

The home screen SHALL display banner **「连接失败，请检查网络后点击重连」** and a one-time snackbar when history WebSocket phase is `gaveUp`. 当历史 WebSocket phase 为 **`gaveUp`** 时，主页**必须**展示 **「连接失败，请检查网络后点击重连」** 横幅，并**必须**弹出**一次性** Snackbar 提示（同主题文案）。

#### Scenario: 第三次 strike 后 UI

- **WHEN** 历史 WebSocket 进入 gave-up（连续 3 次 handshake 失败）
- **THEN** 横幅文案**必须**为「连接失败，请检查网络后点击重连」
- **AND** 必须展示**一次性** Snackbar（同一 gave-up 周期内不得重复 spam）

#### Scenario: gave-up 横幅仍可点击

- **WHEN** gave-up 横幅可见且用户点击
- **THEN** 客户端**必须** reset strike 并发起重连
- **AND** 重连成功后就绪时横幅**必须**隐藏

## MODIFIED Requirements

### Requirement: Inline banner when history WebSocket is not ready

The home screen SHALL display a full-width inline banner between the history list region and the bottom input panel when the history WebSocket is not ready, with phase-specific text: **「正在重连…」** for `autoReconnecting`, **「连接失败，请检查网络后点击重连」** for `gaveUp`, and **「连接中断，请点击重连」** for other not-ready disconnect states. 当历史 WebSocket 未就绪时，主页**必须**在历史记录模块与底部输入模块之间展示全宽内联横幅；文案**必须**按 phase 区分：**autoReconnecting** →「正在重连…」；**gaveUp** →「连接失败，请检查网络后点击重连」；其它未就绪断开态 →「连接中断，请点击重连」。

#### Scenario: Banner visible while disconnected

- **WHEN** 用户已登录且已绑定宝宝，且历史 WebSocket 未就绪（`isHistoryWebSocketReady == false`）
- **THEN** 历史列表与输入区之间**必须**显示上述 phase 对应横幅
- **AND** AppBar **不得**再展示历史 WebSocket 云图标（重连入口仅保留横幅）

#### Scenario: Banner hidden when connected

- **WHEN** 历史 WebSocket 变为已就绪（phase `ready`）
- **THEN** 内联横幅**必须**隐藏
- **AND** 不得遮挡或缩小历史列表的永久占位（仅移除横幅高度）

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未登录或未绑定宝宝
- **THEN** **不得**展示历史 WS 断开横幅（避免无意义提示）

### Requirement: Tap banner reconnects history WebSocket

Tapping the inline banner SHALL invoke reconnect, reset the 3-strike counter to 0, and exit gave-up before reconnecting. 用户点击横幅**必须**触发历史 WebSocket 重连；点击时**必须**先将 3-strike 计数 reset 为 **0** 并退出 gave-up，再调用 `reconnectHistoryWebSocket`（或等价）。

#### Scenario: User taps banner to reconnect

- **WHEN** 横幅可见且用户点击横幅任意可点击区域
- **THEN** 客户端**必须** reset strike 并发起历史 WebSocket 重连
- **AND** 连接并就绪成功后横幅**必须**按「已连接」场景隐藏

#### Scenario: Reconnect does not block history scroll

- **WHEN** 横幅展示中
- **THEN** 历史列表区域**必须**仍可独立滚动
- **AND** 横幅**不得**覆盖在历史列表之上（必须为布局兄弟节点，位于列表下方）
