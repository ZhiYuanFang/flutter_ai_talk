## MODIFIED Requirements

### Requirement: Inline banner when history WebSocket is not ready

The home screen SHALL display a full-width inline banner between the history list region and the bottom input panel **only when** the history WebSocket phase is `gaveUp`, session token refresh is not in flight, **and the home input channel is voice**. 主页**仅当**历史 WebSocket phase 为 **`gaveUp`**、**`isRefreshInFlight == false`**、且当前输入模式为**语音**时，**必须**在历史列表与底部输入区之间展示全宽内联错误横幅；按钮模式（及 Web 文字模式）下即使 `gaveUp` **不得**展示该历史 WS 连接状态横幅。其余未就绪态（含初次进入、`disconnected`、`autoReconnecting`、`isRefreshInFlight == true`）**不得**展示任何历史 WS 连接状态横幅。

| 条件 | 横幅 |
|------|------|
| `gaveUp` 且已登录、已绑定、`isRefreshInFlight == false`、**语音模式** | **「连接失败，请检查网络后点击重连」**（错误/警示态；可点击重连） |
| 按钮模式 / Web 文字模式（任意 WS phase） | （隐藏） |
| `ready` / `disconnected` / `autoReconnecting` / refresh in flight / 未登录 / 未绑定 | （隐藏） |

**`autoReconnecting` 期间 MUST NOT 展示任何历史 WS 连接状态横幅**。未登录或未绑定宝宝时**不得**展示 WS 横幅。

#### Scenario: Banner hidden in button mode even when gaveUp

- **WHEN** 用户已登录且已绑定宝宝，且 `historyWsPhase == gaveUp`，且 `isRefreshInFlight == false`
- **AND** 当前输入模式为按钮
- **THEN** **不得**展示历史 WS 连接状态横幅

#### Scenario: Banner visible on gave up in voice mode

- **WHEN** 用户已登录且已绑定宝宝，且 phase 为 `gaveUp`，且 `isRefreshInFlight == false`
- **AND** 当前输入模式为语音
- **THEN** 横幅文案**必须**为 **「连接失败，请检查网络后点击重连」**
- **AND** 用户点击**必须**可触发重连（reset strike）

#### Scenario: Banner hidden during auto reconnect

- **WHEN** 用户已登录且已绑定宝宝，且 `historyWsPhase == autoReconnecting`
- **THEN** 历史列表与输入区之间**不得**显示历史 WS 连接状态横幅

#### Scenario: Banner hidden when connected

- **WHEN** 历史 WebSocket 变为已就绪（phase `ready` 且 `isHistoryWebSocketReady == true`）
- **THEN** 内联横幅**必须**隐藏

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未登录或未绑定宝宝
- **THEN** **不得**展示历史 WS 断开/恢复横幅
