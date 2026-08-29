## MODIFIED Requirements

### Requirement: Prediction lock ORs VIP with permanent count
On the smart prediction page, a row MUST be usable when its **current display index** in the sorted prediction list is strictly less than permanent `allowedCount`, OR when `isVip` is true. The display index MUST be the row’s position in the list after the page’s current sort (e.g. by nextAt), NOT a fixed binding to a non-leaf event id. When the list is re-sorted, the client MUST re-evaluate locks by the new indices against the same `allowedCount`. The client MUST NOT treat VIP as increasing the permanent activation inventory shown on the unlock hub. 预测页行可用条件：当前排序列表下标 `< allowedCount`，或 `isVip`；槽位跟排序走，不跟固定非叶子 eventId；VIP 不增加 Hub 永久库存展示。

#### Scenario: VIP unlocks view without buying
- **WHEN** isVip is true and index >= allowedCount
- **THEN** the prediction row is usable without lock overlay

#### Scenario: VIP expires
- **WHEN** isVip becomes false
- **THEN** rows beyond permanent allowedCount are locked again

#### Scenario: Sort changes which events occupy unlocked slots
- **WHEN** permanent allowedCount is N and the prediction list re-sorts so a previously locked event moves into index < N
- **THEN** that event becomes usable without requiring an additional purchase, and an event that moved to index >= N becomes locked again (unless isVip)
