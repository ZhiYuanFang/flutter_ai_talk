## ADDED Requirements

### Requirement: Slot-full dialog copy MAY reference defaultCount without changing the gate
The forecast toggle slot gate (block enable when non-VIP and enabledCount >= allowedCount, VIP bypass, disable always allowed) MUST remain unchanged. The confirm dialog message MUST follow `prediction-catalog-default-count` when choosing between default-enabled copy and generic already-enabled copy. 满额再开闸条件不变；弹框文案分支遵循 prediction-catalog-default-count。

#### Scenario: Gate still blocks at allowedCount
- **WHEN** isVip is false, allowedCount is 2, enabledCount is 2, and the user turns on another event
- **THEN** enable MUST fail and the slot dialog MUST appear regardless of defaultCount

#### Scenario: Zero allowedCount copy unchanged
- **WHEN** allowedCount is 0 and the slot dialog appears
- **THEN** the message MUST still explain that no slots are available (不得仅因 defaultCount 改写为零槽位语义)
