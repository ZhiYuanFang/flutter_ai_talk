## ADDED Requirements

### Requirement: Non-VIP hot state MUST cap forecast-enabled count to allowedCount
On the smart prediction page in hot state (logged-in, baby bound, not demo skeleton), when VIP status is settled and the user is not VIP, and permanent `allowedCount` is a non-negative finite cap, the client MUST ensure the number of forecast-enabled root events is less than or equal to `allowedCount`. When `enabledCount` exceeds `allowedCount`, the client MUST disable forecast for enough currently enabled events and persist those disables so that `enabledCount <= allowedCount` afterward. Which excess events are disabled is unspecified (any deterministic choice is allowed). The client MUST NOT change the prediction list sort comparator or the prediction algorithm (nextAt / interval / chart inputs) to achieve this cap. 已登录已绑定热态、VIP 已结算且非 VIP、永久 allowedCount 为非负有限值时，推演开启数必须 ≤ allowedCount；超额必须关闭并持久化足够条数；关谁任意；不得借此改排序或预测算法。

#### Scenario: New user default-all-on is trimmed to N
- **WHEN** hot state loads with empty disabled set (all roots forecast-enabled), isVip is false, allowedCount is 2, and root count is greater than 2
- **THEN** after alignment the client MUST have at most 2 forecast-enabled roots persisted

#### Scenario: Downgrade or smaller allowedCount trims excess
- **WHEN** hot state has 5 forecast-enabled roots, isVip is false, and allowedCount becomes 2
- **THEN** the client MUST disable enough enabled roots so that enabledCount is 2, without auto-enabling any previously disabled root

#### Scenario: Under quota MUST NOT auto-enable
- **WHEN** isVip is false, allowedCount is 5, and enabledCount is 2
- **THEN** the client MUST NOT automatically enable additional roots to fill slots

#### Scenario: VIP exempt from trim
- **WHEN** isVip is true and enabledCount exceeds allowedCount
- **THEN** the client MUST NOT force-disable forecast roots for slot capping

#### Scenario: Demo skeleton exempt from trim
- **WHEN** the prediction page shows the unbound/unauthenticated demo skeleton
- **THEN** skeleton cards MAY remain forecast-enabled for demo and MUST NOT run permanent-slot trim

#### Scenario: Sort and prediction math unchanged
- **WHEN** slot alignment runs because enabledCount > allowedCount
- **THEN** list ordering rules and nextAt/prediction computation MUST remain the same as before this change (only forecastEnabled / disabled persistence may change)
