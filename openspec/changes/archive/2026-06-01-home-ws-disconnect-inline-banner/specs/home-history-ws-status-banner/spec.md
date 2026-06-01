## ADDED Requirements

### Requirement: Inline banner when history WebSocket is not ready

The home screen SHALL display a full-width inline banner between the history list region and the bottom input panel when the history WebSocket is not ready (`isHistoryWebSocketReady == false`), with the text **「连接中断，请点击重连」**. 当历史 WebSocket 未就绪时，主页**必须**在历史记录模块与底部输入模块之间展示全宽内联横幅，文案为 **「连接中断，请点击重连」**。

#### Scenario: Banner visible while disconnected

- **WHEN** 用户已登录且已绑定宝宝，且历史 WebSocket 未连接或已断开
- **THEN** 历史列表与输入区之间**必须**显示上述横幅
- **AND** AppBar **不得**再展示历史 WebSocket 云图标（重连入口仅保留横幅）

#### Scenario: Banner hidden when connected

- **WHEN** 历史 WebSocket 变为已就绪
- **THEN** 内联横幅**必须**隐藏
- **AND** 不得遮挡或缩小历史列表的永久占位（仅移除横幅高度）

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未登录或未绑定宝宝
- **THEN** **不得**展示历史 WS 断开横幅（避免无意义提示）

### Requirement: Tap banner reconnects history WebSocket

Tapping the inline banner SHALL invoke `reconnectHistoryWebSocket` (or equivalent feed repository reconnect). 用户点击横幅**必须**触发历史 WebSocket 重连（如 `reconnectHistoryWebSocket`）。

#### Scenario: User taps banner to reconnect

- **WHEN** 横幅可见且用户点击横幅任意可点击区域
- **THEN** 客户端**必须**发起历史 WebSocket 重连
- **AND** 连接成功后横幅**必须**按「已连接」场景隐藏

#### Scenario: Reconnect does not block history scroll

- **WHEN** 横幅展示中
- **THEN** 历史列表区域**必须**仍可独立滚动
- **AND** 横幅**不得**覆盖在历史列表之上（必须为布局兄弟节点，位于列表下方）

### Requirement: Banner visual affordance

The banner SHALL use error or warning styling consistent with the existing disconnected cloud icon semantics so users recognize actionable recovery. 横幅**必须**采用与现有断开云图标一致的错误/警示视觉（如图标 + 对比色底），使用户识别为可点击的恢复操作。

#### Scenario: Readable on shell background

- **WHEN** 横幅展示于主页 shell 背景之上
- **THEN** 文案与图标**必须**满足可读对比度（浅色/深色主题下均可见）
