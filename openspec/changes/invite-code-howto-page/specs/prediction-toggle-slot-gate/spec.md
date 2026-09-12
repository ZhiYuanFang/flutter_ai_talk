## MODIFIED Requirements

### Requirement: Forecast toggle consumes permanent slots
On the smart prediction page, the client MUST NOT cover prediction event cards with a commercial `FeatureLockOverlay` for slot gating. Enabling forecast for an event (toggle off→on) MUST succeed when `isVip` is true, OR when the count of currently forecast-enabled events is strictly less than permanent `allowedCount`. When `isVip` is false and that count is already greater than or equal to `allowedCount`, the client MUST leave the toggle off and MUST show the shared invite-code dialog (feature_unlock UI module) with title「预测槽位已满」, body「输入邀请码，永久激活一个槽位」, confirm label「激活」, and left action「获取邀请码」. If the user confirms with a non-empty invite code, the client MUST redeem via `POST .../invite-codes/redeem` with `featureId=prediction_unlock`; on success the client MUST toast开通成功 (or equivalent success copy), refresh feature catalog, and automatically enable forecast for the current event. If the user confirms with an empty code, the client MUST navigate to the feature unlock hub (`/features/unlock`). If the user chooses「获取邀请码」, the client MUST open the「如何获取邀请码」screen. Turning forecast off MUST always be allowed. 预测页不得用商业锁浮层做槽位闸；满额展示共享邀请码弹窗；有码兑 prediction_unlock 成功后 toast 并自动开当前开关；空码激活进开通中心；获取邀请码进如何获取页；VIP 开开关全放行；关开关始终允许。

#### Scenario: Enable within quota
- **WHEN** isVip is false, allowedCount is 3, and 2 events currently have forecast enabled, and the user turns on forecast for a third event
- **THEN** the client enables forecast for that event without showing the slot dialog

#### Scenario: Enable blocked shows invite dialog
- **WHEN** isVip is false, allowedCount is 3, and 3 events already have forecast enabled, and the user turns on forecast for another event
- **THEN** that event remains disabled and the shared invite dialog appears with title「预测槽位已满」and body「输入邀请码，永久激活一个槽位」

#### Scenario: Empty activate navigates to unlock hub
- **WHEN** the slot-full invite dialog is shown and the user taps「激活」with an empty code
- **THEN** the client MUST navigate to `/features/unlock`

#### Scenario: Non-empty activate redeems and enables
- **WHEN** the slot-full invite dialog is shown and the user taps「激活」with a non-empty code that redeems successfully for `prediction_unlock`
- **THEN** the client MUST show a success toast
- **AND** MUST refresh catalog
- **AND** MUST enable forecast for the event that triggered the dialog

#### Scenario: Get invite code opens how-to
- **WHEN** the slot-full invite dialog is shown and the user taps「获取邀请码」
- **THEN** the client MUST open the「如何获取邀请码」screen

#### Scenario: VIP may enable without slot check
- **WHEN** isVip is true and enabledCount is already >= allowedCount
- **THEN** the user can turn on forecast for an additional event without the slot dialog

#### Scenario: Disable always allowed
- **WHEN** the user turns off forecast for an enabled event
- **THEN** the client disables forecast immediately regardless of allowedCount or VIP

#### Scenario: No lock overlay on cards
- **WHEN** the prediction list renders and isVip is false and some rows would previously have been index-locked
- **THEN** those cards MUST render without `FeatureLockOverlay` for prediction slot gating
