## MODIFIED Requirements

### Requirement: Inline banner when clinic WebSocket is not ready

The smart companion screen SHALL display a full-width inline banner below the app bar region and above the conversation list **only when** the clinic WebSocket phase is `gaveUp` and session token refresh is not in flight. 智能陪伴页**仅当** Clinic WebSocket phase 为 **`gaveUp`** 且 **`isRefreshInFlight == false`** 时，**必须**在顶栏与对话列表之间展示全宽内联错误横幅；其余未就绪态（含进入页面、`disconnected`、`autoReconnecting`、`isRefreshInFlight == true`）**不得**展示任何 Clinic WS 连接状态横幅。

| 条件 | 横幅 |
|------|------|
| 未同意告知 / 未登录 / 未绑定宝宝 | （隐藏） |
| `gaveUp` 且已登录、已绑定、`isRefreshInFlight == false` | **「连接失败，请检查网络后点击重连」**（错误/警示态；可点击重连） |
| `ready` / `disconnected` / `autoReconnecting` / refresh in flight | （隐藏） |

`autoReconnecting` 期间 **MUST NOT** 展示任何 Clinic WS 连接状态横幅。refresh 明确失败导致未登录时**不得**展示 WS 横幅（由空态与登录 Toast 承担）。

#### Scenario: Banner hidden during auto reconnect

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `clinicWsPhase == autoReconnecting`
- **THEN** 顶栏与对话列表之间**不得**显示 Clinic WS 连接状态横幅
- **AND** 对话列表**必须**仍可独立滚动

#### Scenario: Banner hidden on companion screen entry before WS ready

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且刚进入智能陪伴页，Clinic WS 尚未就绪
- **AND** `isClinicWebSocketReady == false` 且 phase 为 `disconnected`
- **THEN** **不得**展示 Clinic WS 连接状态横幅

#### Scenario: Banner hidden when disconnected and not gave up

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `isClinicWebSocketReady == false`，且 phase 为 `disconnected`，且 `isRefreshInFlight == false`
- **THEN** **不得**展示任何 Clinic WS 连接状态横幅
- **AND** 底层 **必须**仍可按既有规则自动重连

#### Scenario: Banner hidden during token refresh in flight

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 `SessionController.isRefreshInFlight == true`，且 Clinic WS 尚未就绪
- **THEN** **不得**展示任何 Clinic WS 连接状态横幅

#### Scenario: Banner visible on gave up

- **WHEN** 用户已同意告知、已登录且已绑定宝宝，且 phase 为 `gaveUp`，且 `isRefreshInFlight == false`
- **THEN** 横幅文案**必须**为 **「连接失败，请检查网络后点击重连」**
- **AND** 用户点击**必须**可触发重连（reset strike）

#### Scenario: Banner hidden when connected

- **WHEN** Clinic WebSocket 变为已就绪（`isClinicWebSocketReady == true`）
- **THEN** 内联横幅**必须**隐藏

#### Scenario: Banner hidden when not applicable

- **WHEN** 用户未同意告知、未登录或未绑定宝宝
- **THEN** **不得**展示 Clinic WS 断开/恢复横幅

### Requirement: Clinic WS client exposes phase and ready streams to UI

`ClinicWsClient` MUST expose synchronous and streaming clinic WebSocket readiness and phase state derived from the internal `ResilientWebSocketClient`, mapped to `HistoryWsPhase` for UI consumption. `ClinicWsClient` **必须**向 UI 暴露基于内部 `ResilientWebSocketClient` 的同步/流式就绪态与 phase（映射为 `HistoryWsPhase`），供智能陪伴页驱动横幅。

#### Scenario: Phase stream emits on transport phase change

- **WHEN** 内部 transport phase 从 `disconnected` 变为 `autoReconnecting` 或 `ready`
- **THEN** `clinicWsPhaseStream` **必须**向监听方推送映射后的 `HistoryWsPhase`
