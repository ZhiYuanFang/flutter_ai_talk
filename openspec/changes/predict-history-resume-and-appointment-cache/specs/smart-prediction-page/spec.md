## MODIFIED Requirements

### Requirement: Prediction pull-to-refresh SHALL reload home page 1 and seven-day range

On each user pull-to-refresh gesture on the smart prediction page, the client MUST refresh the shared history pool with the same **rolling 24-hour** merge semantics as logged-in app resume (`now − 24h` through `now`, merge by id, preserve older local rows outside the window). The client MUST NOT force a full near-seven-day history seed solely because of this gesture, MUST NOT deepen history via `loadNextHistoryPage` / load-more, and MUST NOT run the full home-shell resume HTTP bundle (UCG unread sync and other resume-only work). The client MUST NOT invoke predict-imminent or active-ETA pending PUT APIs solely because the user pulled to refresh; those remain driven by existing post-mutation schedule / eligible local-mutation sync paths after history updates (not by pull alone). Per gesture, the client MUST initiate at most one active rolling-24h history refresh (additional coalescing by existing single-flight is allowed).

In the same gesture, the client MUST also silently refresh appointment **next** and appointment **last** for appointment roots (network ensure that MUST NOT skip solely because memory already holds values), in parallel with the history refresh. Appointment-only failure MUST NOT by itself count as the history-path failure toast defined below.

用户每次下拉 MUST 对统一池做滚动 24h 合并，并并行静默刷新预约 next/last；MUST NOT force 近 7 日种子、触顶加载更多、整包 resume、或仅因下拉直接打 imminent / active-ETA PUT。

#### Scenario: 一手势刷新 24h 历史与预约

- **WHEN** 用户在已绑定且已登录状态下完成一次预测页下拉刷新
- **THEN** 客户端 MUST 对统一历史池执行滚动 24h filter 合并（保留窗外更旧行）
- **AND** MUST 发起预约 next 与 last 的网络刷新（可与历史并行）
- **AND** MUST NOT 仅因本次下拉 force 近 7 日历史种子
- **AND** MUST NOT 因此调用 `loadNextHistoryPage`（或等价加载更旧页）

#### Scenario: 不整包 resume

- **WHEN** 用户仅触发预测页下拉刷新（非 App 回前台）
- **THEN** 客户端 MUST NOT 仅因此执行 UCG unread sync（resume bundle 其余项）

#### Scenario: 不直接打 pending PUT

- **WHEN** 用户下拉刷新，且本手势未伴随本机合格历史/间隔/预约变更同步路径
- **THEN** 客户端 MUST NOT 仅因该下拉手势新增一轮 imminent / active-ETA pending PUT

### Requirement: Prediction pull-to-refresh failure SHALL toast

When the rolling-24h history refresh initiated by a prediction pull-to-refresh gesture fails (network/API failure or documented equivalent), the client MUST show an error toast via `showAppToast` (or equivalent) informing the user that refresh failed. Failure of appointment next/last silent refresh alone MUST NOT cause that failure toast. When the history path succeeds, the client MUST NOT show a success toast solely for that gesture. The `RefreshIndicator` MUST complete (stop spinning) after the history path and the appointment next/last refresh paths initiated by the gesture have all settled, whether those paths succeed or fail. Prior successful history pool and appointment cache MUST remain visible on failure.

下拉刷新时历史 24h 路径失败 MUST Toast；**仅**预约静默刷新失败 MUST NOT 单独触发该失败 Toast；历史成功 MUST NOT 仅因此弹成功 Toast；指示器 MUST 在历史与预约路径均结算后结束；失败 MUST 保留上次成功展示。

#### Scenario: 历史失败 Toast

- **WHEN** 用户下拉且滚动 24h 历史刷新失败（无论预约刷新成败）
- **THEN** 客户端 MUST 展示错误 Toast（刷新失败语义）
- **AND** `RefreshIndicator` MUST 结束加载反馈
- **AND** MUST 继续展示下拉前已有历史/预约数据

#### Scenario: 仅预约失败不 Toast

- **WHEN** 用户下拉且滚动 24h 历史成功，但预约 next 或 last 静默刷新失败
- **THEN** 客户端 MUST NOT 仅因此展示「刷新失败」错误 Toast
- **AND** `RefreshIndicator` MUST 仍在本手势路径均结算后结束

#### Scenario: 双成功无成功 Toast

- **WHEN** 用户下拉且历史与预约路径均成功
- **THEN** 客户端 MUST NOT 仅因此展示成功 Toast
- **AND** `RefreshIndicator` MUST 在含预约在内的本手势路径均结算后结束加载反馈

## REMOVED Requirements

### Requirement: Prediction pull-to-refresh SHALL sync history latest-by-event

**Reason**: 卡面「上一次」主源改为统一历史池；下拉改为滚动 24h 合并 + 预约 next/last，不再要求并行 latest-by-event。

**Migration**: 展示与重算跟池；post-mutation 若仍调用 latest-by-event 可作后台可选，不得作为下拉成功条件或失败 Toast 条件。
