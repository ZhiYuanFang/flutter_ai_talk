## ADDED Requirements

### Requirement: Prediction card lastAt SHALL prefer the shared history pool

When building smart-prediction card「上一次」display and the `lastAt` used for next-event math on **non-appointment** roots, the client MUST first resolve occurrence time (and remark when shown) from the shared home history pool for the same prediction bucket: when the card has a non-null `prediction`, MUST use only that `prediction.eventId` bucket; when `prediction` is null, MAY use the catalog root. Only when the pool cannot supply a usable last occurrence for that bucket MAY the client fall back to the tip / `EventLastAtStore` cache for the same id. The client MUST NOT treat `GET /device/history/api/event/latest-by-event` as the primary display source. **Appointment** roots MUST follow `appointment-event-client` / `appointment-local-cache-silent-refresh`（展示只认预约 last 缓存 + 静默不限窗 filter），and MUST NOT read `appointment_next` as last occurrence, and MUST NOT use the shared history pool as the appointment last display primary.

非预约卡上一次 MUST 优先统一历史池同桶；池无 MAY 回落 tip；MUST NOT 以 latest-by-event 为展示主源；预约只认预约 last 缓存；有 prediction 时 MUST 与 `prediction.eventId` 同桶。

#### Scenario: Pool has category last

- **WHEN** 统一历史池对某预测桶已有至少一条匹配真记录
- **AND** 客户端计算该卡 lastAt 展示或 next 推算
- **THEN** 客户端 MUST 使用池内该桶最新记录时间作为 lastAt 主来源
- **AND** MUST NOT 仅因 latest-by-event / tip 返回不同 lastAt 而覆盖池内结果

#### Scenario: Pool empty falls back to tip

- **WHEN** 统一历史池对该预测桶无可匹配记录
- **AND** tip / EventLastAtStore 对该同 id 有可用 lastAt
- **THEN** 客户端 MAY 使用 tip lastAt 作为回落，直到池内出现该桶记录

#### Scenario: Resume 24h merge updates lastAt without seven-day force

- **WHEN** resume 滚动 24h 合并将某桶更新进统一池
- **THEN** 依赖该桶 lastAt 的预测卡与推算 MUST 能反映池内更新
- **AND** MUST NOT 要求再跑一次近 7 日种子或 latest-by-event 才更新卡面

#### Scenario: Non-merge winning child last stays in child bucket

- **WHEN** 非合并根卡胜出子为 AD（`prediction.eventId=AD`），兄弟 3D 的最近发生晚于 AD，且池内 3D/根更新
- **THEN** 该卡展示 lastAt MUST 仍为 AD 桶的最近发生（或 AD 桶无数据则为空/ tip），MUST NOT 展示 3D/根聚合的更新时刻
