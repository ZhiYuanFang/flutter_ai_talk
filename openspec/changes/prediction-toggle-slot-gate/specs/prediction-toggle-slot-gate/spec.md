## ADDED Requirements

### Requirement: Forecast toggle consumes permanent slots
On the smart prediction page, the client MUST NOT cover prediction event cards with a commercial `FeatureLockOverlay` for slot gating. Enabling forecast for an event (toggle off→on) MUST succeed when `isVip` is true, OR when the count of currently forecast-enabled events is strictly less than permanent `allowedCount`. When `isVip` is false and that count is already greater than or equal to `allowedCount`, the client MUST leave the toggle off, MUST show a confirm dialog explaining that more slots are required, and on confirm MUST navigate to the feature unlock hub (`/features/unlock`). Turning forecast off MUST always be allowed. 预测页不得用商业锁浮层做槽位闸；开预测开关按「已开启条数 vs 永久 allowedCount」计数，满额弹框确认后进开通中心；VIP 开开关全放行；关开关始终允许。

#### Scenario: Enable within quota
- **WHEN** isVip is false, allowedCount is 3, and 2 events currently have forecast enabled, and the user turns on forecast for a third event
- **THEN** the client enables forecast for that event without showing the slot dialog

#### Scenario: Enable blocked when full
- **WHEN** isVip is false, allowedCount is 3, and 3 events already have forecast enabled, and the user turns on forecast for another event
- **THEN** that event remains disabled, a confirm dialog is shown, and confirming navigates to `/features/unlock`

#### Scenario: VIP may enable without slot check
- **WHEN** isVip is true and enabledCount is already >= allowedCount
- **THEN** the user can turn on forecast for an additional event without the slot dialog

#### Scenario: Disable always allowed
- **WHEN** the user turns off forecast for an enabled event
- **THEN** the client disables forecast immediately regardless of allowedCount or VIP

#### Scenario: No lock overlay on cards
- **WHEN** the prediction list renders and isVip is false and some rows would previously have been index-locked
- **THEN** those cards MUST render without `FeatureLockOverlay` for prediction slot gating
