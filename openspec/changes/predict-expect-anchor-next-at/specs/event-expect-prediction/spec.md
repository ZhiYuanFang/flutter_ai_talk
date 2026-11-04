## ADDED Requirements

### Requirement: Pre-start expect query anchor MUST be prediction nextAt

When the client attaches a winning expect (duration or amount) onto an existing non-appointment root prediction that already has a computed `nextAt`, the time-of-day bucket and recency half-life **query** anchor for that expect computation SHALL be `prediction.nextAt`. The client MUST NOT use `prediction.lastAt` as that query anchor. This MUST NOT change per-sample weighting timestamps: each duration sample’s bucket/recency instant remains that record’s `startTime`; each amount sample remains its occurrence instant. In-progress active-timing ETA MUST continue to query-anchor on the active record’s `startAt` (unchanged).

开事前将胜出 expect 挂到已有 `nextAt` 的非预约根预测上时，duration/amount 加权的**查询锚点** MUST 为该预测的 `nextAt`，MUST NOT 再用 `lastAt`。样本自身加权时刻不变（duration 仍为该次 `startTime`；amount 仍为发生时刻）。进行中 ETA 的查询锚仍为本次 `startAt`。

#### Scenario: Pre-start duration uses nextAt bucket not lastAt

- **WHEN** 某非预约根 `lastAt` 落在日间时段桶、`nextAt` 落在晚间时段桶，且根下日间短睡与夜间长睡的 duration 样本均足以参与加权
- **THEN** 开事前挂载的 duration `expectDurationSec`（若 duration 胜出）MUST 按以 `nextAt` 为查询锚的加权中位计算，MUST NOT 仍以 `lastAt` 为查询锚以致系统性地贴近日间短睡中位

#### Scenario: Day-nap lastAt evening nextAt overnight duration

- **WHEN** 根下至少有 2 条日间短睡（约 1 小时）与 2 条夜间长睡（约 10 小时）已结束计时，且间隔推演给出 `lastAt` 为上午、`nextAt` 约为 19:00，且胜出 expectKind 为 `duration`
- **THEN** 开事前 `expectDurationSec` MUST 明显贴近夜间长睡量级（约 10 小时中位一侧），MUST NOT 明显贴近日间短睡量级（约 1 小时）

#### Scenario: Active ETA still anchors on startAt

- **WHEN** 用户于该根 `nextAt` 附近开始计时且 duration 有把握
- **THEN** 进行中 `expectEndAt` MUST 仍由本次 `startAt` 作查询锚的 duration 中位推得（本 Requirement 不得改为用历史 `lastAt`）

#### Scenario: Amount pre-start also uses nextAt query anchor

- **WHEN** 胜出 expectKind 为 `amount`，且该根已有 `nextAt`
- **THEN** amount 加权查询锚点 MUST 为该 `nextAt`（MUST NOT 为 `lastAt`）
