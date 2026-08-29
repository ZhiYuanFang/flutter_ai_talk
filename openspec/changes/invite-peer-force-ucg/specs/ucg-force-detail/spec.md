## ADDED Requirements

### Requirement: Force tier icon opens points detail
The client SHALL make the UCG force/level icon on 我的 tappable and SHALL open a points detail screen. The detail screen MUST show current `forceValue`, a ledger of point events, how points are earned (debate +1, acquisition ×100), and points remaining to the next tier computed **on the client** from local thresholds. The client MUST NOT require a server `nextTierAt` field.

#### Scenario: Below first tier
- **WHEN** forceValue is below 500
- **THEN** the detail still shows the numeric score and remaining points to bronze

#### Scenario: Ledger entries
- **WHEN** the ledger API returns debate and acquisition rows
- **THEN** both reason types are visible with deltas
