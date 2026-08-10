## ADDED Requirements

### Requirement: Care-alert ensure SHALL run when fetch gate becomes allowed

While the smart prediction page is the visible home hub page, when `predictionCareAlertFetchAllowed` (or equivalent: logged in, deviceNo present, seven-day range ready with non-empty items) transitions from not-allowed to allowed, the client MUST invoke care-alert `ensureLoaded` (single-flight). The client MUST NOT rely solely on a one-shot post-frame callback that may run before the range is ready. Automatic ensure MUST still be skipped when the fetch gate is not allowed (no true history).

预测页作为可见主页时，拉取门闸从不可用变为可用，客户端 **必须** 调用 care-alert `ensureLoaded`（single-flight）；**不得** 仅依赖可能早于 range 就绪的一次性 postFrame；门闸未放行时自动 ensure **仍必须** 跳过。

#### Scenario: range 就绪后补拉

- **WHEN** 用户已登录且 deviceNo 可用
- **AND** 七日 range 从「未就绪或空」变为 ready 且 items 非空
- **AND** 当前停在智能预测页
- **THEN** 客户端 MUST 发起 `GET /device/api/care-alert/daily`（或等价 ensure）
- **AND** Debug 下 MUST 出现 `[CareAlert]` 成功或失败日志

#### Scenario: 无真历史不自动拉

- **WHEN** range ready 但 items 为空
- **THEN** 客户端 MUST NOT 因预测页可见而自动请求 care-alert daily

### Requirement: Care-alert gate skips SHALL be logged in debug

When an automatic or explicit ensure path skips because the session is logged out, deviceNo is missing, or the fetch gate is not allowed, the client MUST emit an `AppDebugLog.careAlert` (or `[CareAlert]`) diagnostic in debug builds that summarizes the skip reason without requiring a network call. Silent no-op returns without such a log are forbidden for those skip paths.

因未登录、无 deviceNo 或门闸未放行而跳过 ensure 时，Debug 下 **必须** 打出 `[CareAlert]` 跳过摘要；上述路径 **禁止** 无日志静默 return。

#### Scenario: 门闸未放行可观测

- **WHEN** 预测页触发 ensure 但 range 尚未 ready
- **THEN** Debug log MUST 含 CareAlert 跳过信息（可含 range.ready / itemCount 等因子）
- **AND** MUST NOT 发起 care-alert daily HTTP

### Requirement: Idle not-ready care-alert card MUST NOT show perpetual loading copy

When care-alert state is not loading and not ready (including never-fetched after gate skip), the prediction-page care-alert card MUST NOT present the body solely as「加载中…」. The client MUST show the empty-family presentation with a refresh control (VIP/non-VIP copy per current care-alert empty-family rules). True in-flight fetch (`loading == true`) MAY continue to show「加载中…」.

当留意状态非 loading 且未 ready（含门闸跳过导致从未拉取）时，卡片正文 **不得** 仅显示「加载中…」；**必须** 展示带刷新的空态族；仅 `loading==true` 时 **可** 显示「加载中…」。

#### Scenario: 从未拉取显示可刷新空态

- **WHEN** `loading == false` 且 `ready == false` 且 `failed == false`
- **THEN** 卡片 MUST NOT 仅显示「加载中…」
- **AND** MUST 提供可触发 force ensure 的刷新控件

#### Scenario: 真加载仍显示加载中

- **WHEN** `loading == true`
- **THEN** 卡片正文 MAY 为「加载中…」
