## ADDED Requirements

### Requirement: Prediction unlock card activation copy
On the feature unlock hub, for `prediction_unlock`, the client SHALL show top-right copy「已激活 X 个」using permanent `allowedCount`, or「已全部激活」when `totalActivatableCount > 0` and `allowedCount >= totalActivatableCount`. The client MUST use server-provided `totalActivatableCount` for the all-activated check.

#### Scenario: Partial
- **WHEN** allowedCount is 3 and totalActivatableCount is 10
- **THEN** the card shows「已激活 3 个」

#### Scenario: Complete
- **WHEN** allowedCount >= totalActivatableCount and total > 0
- **THEN** the card shows「已全部激活」

### Requirement: Pay and invite CTAs while not fully activated
While prediction is not fully permanently activated, the client MUST keep showing payment CTA formatted as current price with strikethrough original price and「/个」, and an「输入邀请码开通」action, even if the user is VIP. Ad CTA MUST remain if catalog still lists ad unlock.

#### Scenario: VIP still sees unit purchase
- **WHEN** isVip is true and activation is not complete
- **THEN** pay-per-unit and invite CTAs remain visible

### Requirement: VIP card sticky with validity
The hub MUST show the monthly VIP card sticky at the bottom (not only scrolled with the list) and MUST include validity copy (remaining days or expire date / duration after purchase).

#### Scenario: Sticky vip
- **WHEN** user scrolls the feature list
- **THEN** the VIP card remains pinned at the bottom with validity text
