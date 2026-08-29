## MODIFIED Requirements

### Requirement: Prediction lock ORs VIP with permanent count
On the smart prediction page, commercial slot gating MUST be enforced via the per-event forecast toggle as defined by `prediction-toggle-slot-gate`, NOT via a `FeatureLockOverlay` on the card. A non-VIP user MAY have at most permanent `allowedCount` events with forecast enabled at once; VIP users MUST be allowed to enable forecast without that permanent-count ceiling. The client MUST NOT treat VIP as increasing the permanent activation inventory shown on the unlock hub. The client MUST NOT use sorted display index as the prediction-page lock key. 预测页槽位改为开关开启计数（见 prediction-toggle-slot-gate）；不得再用卡片锁浮层或排序下标作为锁键；VIP 开推演不受永久条数天花板限制，且不增加 Hub 永久库存展示。

#### Scenario: VIP unlocks view without buying
- **WHEN** isVip is true and enabled forecast count is already >= allowedCount
- **THEN** the user can still enable forecast on another event without a slot-purchase dialog

#### Scenario: VIP expires
- **WHEN** isVip becomes false and enabled forecast count is greater than allowedCount
- **THEN** already-enabled forecasts MAY remain on, but enabling any additional forecast MUST show the slot dialog until enabledCount is below allowedCount or the user re-subscribes / purchases slots

#### Scenario: Sort does not change which events are gated
- **WHEN** the prediction list re-sorts
- **THEN** which events may enable forecast MUST depend on enabledCount vs allowedCount (and VIP), NOT on the new display indices
