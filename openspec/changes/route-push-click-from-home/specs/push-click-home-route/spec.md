## ADDED Requirements

### Requirement: Notification tap SHALL be stored until the home shell can route it

The client MUST record the latest notification-tap `bizType` and MUST NOT push a feature route directly from the tap callback. If the current location is not `/home`, the client MUST navigate to `/home` first. The home shell MUST consume the pending value only after `/home` is the active location and the session login state is known. The client MUST NOT wait for prediction lists, history, or unread HTTP before consuming. A newer tap MUST replace an unconsumed value rather than queue. 点击回调 **必须** 只暂存最新 `bizType` 并先进入 `/home`；主页在会话已知后消费，**不得** 排队，**不得** 等预测或未读接口。

#### Scenario: Tap while a child route is open

- **WHEN** 用户在非 `/home` 页面点击一条带可识别 `bizType` 的可见通知
- **THEN** 客户端 MUST 先进入 `/home`
- **AND** MUST 在主页会话状态已知后再按该 `bizType` 分流

#### Scenario: A second tap replaces the first

- **WHEN** 上一次点击的 `bizType` 尚未被主页消费，又收到一次新的点击
- **THEN** 客户端 MUST 只保留最新的 `bizType`

#### Scenario: Cold start does not drop the tap

- **WHEN** 应用进程未在运行，用户点击一条可见通知从而冷启动
- **THEN** 客户端 MUST 在主页就绪后仍能读到该次点击的 `bizType`（或确认该载荷没有可识别 `bizType`）

### Requirement: Home SHALL route known biz types and ignore the rest

After consuming a tap, the home shell MUST apply exactly these outcomes: missing, empty, unknown, or `ucg_silent_badge` values MUST NOT request a page change; when the user is not logged in the shell MUST remain on the prediction page and MUST NOT present the UCG messages-tab login prompt; `predict_imminent` MUST request the prediction page and MUST NOT open UCG; `ucg_alert` while logged in MUST request the UCG pager page. Foreground notification-banner taps MUST use this same path. 主页 **必须** 只对 `predict_imminent` 与已登录的 `ucg_alert` 切页；未登录、未知类型与静默角标 **不得** 额外跳转，前台横幅点击走同一路径。

#### Scenario: Predict-imminent opens the prediction page

- **WHEN** 已消费的 `bizType` 为 `predict_imminent`
- **THEN** 主页 MUST 切到预测主页
- **AND** MUST NOT 进入 UCG 页或消息 Tab

#### Scenario: Logged-out UCG tap stays on prediction

- **WHEN** 用户未登录且已消费的 `bizType` 为 `ucg_alert`
- **THEN** 主页 MUST 留在预测主页
- **AND** MUST NOT 弹出登录提示

#### Scenario: Unknown payload only opens the app

- **WHEN** 点击载荷没有 `bizType`，或值不是 `ucg_alert` 与 `predict_imminent`
- **THEN** 客户端 MUST NOT 因该次点击请求切页

### Requirement: Logged-in UCG tap SHALL open the messages tab after the UCG shell is mounted

When `bizType` is `ucg_alert` and the user is logged in, the client MUST switch to the UCG home page and, once `UcgShell` is mounted, MUST invoke the same handler used by tapping the messages tab (conversation refresh, interaction refresh, and unread sync). The client MUST NOT wait for those HTTP calls to finish before selecting the tab, and MUST NOT synthesize a pointer event. If UCG eligibility is not qualified, the existing lock overlay MUST remain the visible surface; the client MUST NOT navigate to a separate lock route. If the shell is already mounted, the client MUST select the messages tab without waiting for another load cycle. 已登录的 UCG 点击 **必须** 在壳挂载后走消息 Tab 的既有处理；资格未过时可见表面仍是锁层。

#### Scenario: Qualified user reaches the messages list

- **WHEN** 已登录且 UCG 资格已通过的用户点击 `ucg_alert` 通知
- **THEN** 客户端 MUST 切到 UCG 页并进入消息列表
- **AND** MUST 触发与用户点消息 Tab 相同的会话、互动与未读刷新

#### Scenario: Unqualified user stops on the lock overlay

- **WHEN** 已登录但 UCG 资格未通过的用户点击 `ucg_alert` 通知
- **THEN** 可见表面 MUST 为 UCG 页上的既有锁层
- **AND** 客户端 MUST NOT 打开独立的锁页路由

#### Scenario: Shell already mounted

- **WHEN** 用户已停留在已挂载的 UCG 壳上并点击 `ucg_alert` 通知
- **THEN** 客户端 MUST 直接执行消息 Tab 处理
- **AND** MUST NOT 等待新的一轮页面加载完成
