## ADDED Requirements

### Requirement: Smart prediction page SHALL support pull-to-refresh on the cards region

When the smart prediction page is visible (portrait or landscape), the event cards region MUST expose top pull-to-refresh via `RefreshIndicator` (or equivalent). Empty and short card lists MUST remain pullable using always-scrollable physics. The client MUST NOT implement bottom upward-pull refresh on the prediction page. Fixed chrome above the cards region (header, care/guide, notification banner, three-hour timeline) MAY stay outside the pull scrollable.

智能预测页（竖屏与横屏）卡片区 **必须** 支持顶部下拉刷新；空态与短列表 **必须** 仍可拉；**不得** 实现底部上拉刷新。卡片区上方固定 chrome MAY 不在下拉滚动树内。

#### Scenario: 列表可下拉

- **WHEN** 用户在预测页卡片列表（或瀑布）顶部下拉超过系统阈值后松手
- **THEN** 客户端 MUST 触发一次预测页下拉刷新路径（见刷新范围 Requirement）
- **AND** MUST 通过 `RefreshIndicator`（或等价）展示下拉反馈

#### Scenario: 空态可下拉

- **WHEN** 预测页卡片区为空（或内容不足以产生 overscroll）且用户下拉
- **THEN** 客户端 MUST 仍能触发同一下拉刷新路径（MUST 使用 `AlwaysScrollableScrollPhysics` 或等价）

#### Scenario: 无底部上拉

- **WHEN** 用户在预测页卡片区底部向上拖拽
- **THEN** 客户端 MUST NOT 因此触发与顶部下拉相同的刷新路径

### Requirement: Prediction pull-to-refresh SHALL reload home page 1 and seven-day range

On each user pull-to-refresh gesture on the smart prediction page, the client MUST refresh feeding home history page 1 via the existing `refreshFromRemote` path (or documented equivalent) and MUST force-reload the isolated seven-day prediction range store via `ensureLoaded(force: true)` (or equivalent). The gesture MUST NOT deepen home history via `loadNextHistoryPage` / load-more. The gesture MUST NOT run the full home-shell resume HTTP bundle (care-alert ensure, UCG unread sync, and other resume-only work). The client MUST NOT invoke predict-imminent or active-ETA pending PUT APIs solely because the user pulled to refresh; those remain driven by existing fingerprint / schedule paths after history updates. Per gesture, the client MUST initiate at most one active home page-1 refresh and at most one active range force ensure (additional range work coalesced by existing single-flight / home→`scheduleInvalidation` coupling is allowed).

用户每次下拉 **必须** 刷新 home 第 1 页并 force 重拉 7 日 range；**不得** 触顶加载更多；**不得** 整包 resume；**不得** 仅因下拉直接打 imminent / active-ETA PUT；一手势对两路各最多主动一轮。

#### Scenario: 一手势刷新 home 与 range

- **WHEN** 用户在已绑定且已登录状态下完成一次预测页下拉刷新
- **THEN** 客户端 MUST 调用（或等价复用）`homeHistory.refreshFromRemote` 拉取第 1 页
- **AND** MUST 对 `predictionRangeHistory` 执行 force ensure / 重拉
- **AND** MUST NOT 因此调用 `loadNextHistoryPage`（或等价加载更旧页）

#### Scenario: 不整包 resume

- **WHEN** 用户仅触发预测页下拉刷新（非 App 回前台）
- **THEN** 客户端 MUST NOT 仅因此执行 care-alert 全量 ensure 与 UCG unread sync（resume bundle 其余项）

#### Scenario: 不直接打 pending PUT

- **WHEN** 用户下拉刷新且 history/range 指纹相对上次 pending 同步未变
- **THEN** 客户端 MUST NOT 仅因该下拉手势新增一轮 imminent / active-ETA pending PUT

### Requirement: Prediction pull-to-refresh failure SHALL toast

When either the home page-1 refresh or the range force reload initiated by a prediction pull-to-refresh gesture fails (network/API failure or documented equivalent), the client MUST show an error toast via `showAppToast` (or equivalent) informing the user that refresh failed. When both paths succeed, the client MUST NOT show a success toast solely for that gesture. The `RefreshIndicator` MUST complete (stop spinning) after both initiated paths settle, whether success or failure.

下拉刷新时 home 或 range **任一路失败** MUST Toast 失败提示；两路皆成功 MUST NOT 仅因此弹成功 Toast；指示器 MUST 在两路结算后结束。

#### Scenario: range 失败 Toast

- **WHEN** 用户下拉且 range force 拉取失败、home 第 1 页刷新成功
- **THEN** 客户端 MUST 展示错误 Toast（刷新失败语义）
- **AND** `RefreshIndicator` MUST 结束加载反馈

#### Scenario: home 失败 Toast

- **WHEN** 用户下拉且 home 第 1 页刷新失败、range force 拉取成功
- **THEN** 客户端 MUST 展示错误 Toast（刷新失败语义）

#### Scenario: 双成功无成功 Toast

- **WHEN** 用户下拉且 home 与 range 均成功
- **THEN** 客户端 MUST NOT 仅因此展示成功 Toast
- **AND** `RefreshIndicator` MUST 结束加载反馈
