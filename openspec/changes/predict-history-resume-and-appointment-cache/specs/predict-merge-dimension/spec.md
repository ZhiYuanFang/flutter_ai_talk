## MODIFIED Requirements

### Requirement: Prediction last occurrence SHALL use history latest-by-event

The client MUST resolve “last occurrence” for prediction cards primarily from the **shared history pool** for the same prediction bucket (when the card has a non-null `prediction`, MUST use only that `prediction.eventId` bucket; when `prediction` is null, MAY use the catalog root). Only when the pool cannot supply a usable last occurrence for that bucket MAY the client fall back to tip / `EventLastAtStore` for the same id. `GET /device/history/api/event/latest-by-event` MUST NOT be the primary display source (post-mutation or background sync MAY still call it, but MUST NOT override a newer pool last for card display). Appointment card last occurrence MUST follow `appointment-event-client` / `appointment-local-cache-silent-refresh` (pool, then appointment-last cache, then silent unbounded filter) and MUST NOT read `appointment_next` as last occurrence.

For non-appointment cards, the「上一次{事件名}」prefix MUST use the catalog authoritative name of the same bucket used for that last occurrence (`prediction.eventName` / lookup by `prediction.eventId` when prediction is present; otherwise the root display name). The client MUST NOT reuse the card’s top-leading root title string as that prefix when the prediction bucket is a child. Tapping the last-occurrence row on a non-appointment card MUST open the latest real history record in that same bucket (MUST NOT open a sibling child’s record solely because it is newer under the root).

预测卡上一次 MUST 优先统一历史池同桶；池无 MAY tip；MUST NOT 以 latest-by-event 为展示主源；有 prediction 时 MUST 与 `prediction.eventId` 同桶且 MUST NOT 回退根/全窗子；无 prediction 时 MAY 用根；非预约「上一次{名}」与点按编辑 MUST 同桶。

#### Scenario: Pool drives card last line

- **WHEN** 统一历史池含某非预约 eventId 的最近真发生
- **THEN** 对应预测卡「上一次」MUST 使用该时刻（在同桶规则下该卡 lookup id 命中该项时）

#### Scenario: Appointment root last not from nextAt

- **WHEN** 预约根在 history / 预约 last 缓存中有记录
- **THEN** 预约卡「上一次发生」MUST 使用该根历史/缓存发生时刻，MUST NOT 使用 appointment nextAt

#### Scenario: Non-merge winning child last stays in child bucket

- **WHEN** 非合并根卡胜出子为 AD（`prediction.eventId=AD`），兄弟 3D 的最近发生晚于 AD，且池内在根或 3D 上更新
- **THEN** 该卡展示 lastAt MUST 仍为 AD 桶的最近发生（或 AD 桶无数据则为空/ tip），MUST NOT 展示 3D/根聚合的更新时刻；「上一次」前缀 MUST 为 AD 名（MUST NOT 为营养品根名）；点按 MUST 打开 AD 桶最新真记录

#### Scenario: No prediction falls back to root last

- **WHEN** 某根预测卡 `prediction == null` 且根在统一池有最近发生
- **THEN** 展示 lastAt MUST 可使用该根 id；「上一次」前缀 MUST 为根名
