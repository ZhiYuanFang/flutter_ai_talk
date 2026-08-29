## ADDED Requirements

### Requirement: Prediction lock ORs VIP with permanent count
On the smart prediction page, a row MUST be usable when its display index is within permanent `allowedCount` OR when `isVip` is true. The client MUST NOT treat VIP as increasing the permanent activation inventory shown on the unlock hub.

#### Scenario: VIP unlocks view without buying
- **WHEN** isVip is true and index >= allowedCount
- **THEN** the prediction row is usable without lock overlay

#### Scenario: VIP expires
- **WHEN** isVip becomes false
- **THEN** rows beyond permanent allowedCount are locked again
