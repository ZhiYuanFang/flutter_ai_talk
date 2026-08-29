## MODIFIED Requirements

### Requirement: Prediction unlock card activation copy
On the feature unlock hub, for `prediction_unlock`, the client SHALL show top-right copy「已激活 X 个」using permanent `allowedCount`, or「已全部激活」when `totalActivatableCount > 0` and `allowedCount >= totalActivatableCount`. The client MUST use server-provided `totalActivatableCount` for the all-activated check, and MUST interpret that field as the device event-dictionary **non-leaf** count from Go catalog aggregation. The client MUST NOT recompute the ceiling from the number of currently visible prediction rows. 开通中心预测卡：「已激活 X 个」用永久 `allowedCount`；「已全部激活」仅当服务端非叶子 `totalActivatableCount > 0` 且 `allowedCount >= total`；不得用当前可见预测行数当天花板。

#### Scenario: Partial
- **WHEN** allowedCount is 3 and totalActivatableCount is 10
- **THEN** the card shows「已激活 3 个」

#### Scenario: Complete
- **WHEN** allowedCount >= totalActivatableCount and total > 0
- **THEN** the card shows「已全部激活」

#### Scenario: Visible rows fewer than dictionary total
- **WHEN** the prediction page shows fewer rows than totalActivatableCount and allowedCount is still below total
- **THEN** the hub MUST still show「已激活 X 个」(not「已全部激活」) and MUST keep accumulation CTAs when not fully activated
