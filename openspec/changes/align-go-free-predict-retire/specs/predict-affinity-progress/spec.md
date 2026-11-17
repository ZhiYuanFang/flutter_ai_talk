## ADDED Requirements

### Requirement: Affinity progress SHALL count valid occurrences per prediction bucket

When affinity cannot yet produce a `nextAt` for a prediction bucket, the client SHALL compute affinity progress from real history using the same bucket key as prediction (`predictionBucketKeyForEventId`: merge-predict roots count under the root id; split roots count under the leaf event id). Valid occurrence count MUST sort timestamps ascending and increment only when the gap from the previously counted occurrence is at least 15 minutes. Target count MUST be `kMinSamplesForPrediction + 1` (three valid occurrences when the sample gate is 2). Progress ratio MUST be `min(count, target) / target`.

无亲和 nextAt 时，亲和进度 MUST 按预测桶统计有效发生（≥15 分钟间隔）；目标次数 MUST 为样本门闸 +1（默认 3）；合并根按根、拆分按子。

#### Scenario: 三次有效发生达标

- **WHEN** 某合并根桶内有 3 条真实记录且相邻计入间隔均 ≥15 分钟
- **THEN** 该桶有效发生 count MUST 为 3
- **AND** progress MUST 为 1.0

#### Scenario: 过近记录不计第二次

- **WHEN** 同桶两条记录间隔 <15 分钟
- **THEN** 后一条 MUST NOT 增加有效发生 count

#### Scenario: 拆分根按叶子

- **WHEN** 某根 `mergePredict=false` 且叶子 A、B 各有记录
- **THEN** A 与 B MUST 各自独立计进度
- **AND** MUST NOT 合并进根桶计数

### Requirement: Prediction card SHALL show progress bar when affinity nextAt is absent

On smart-prediction event cards (and equivalent list rows that normally show countdown / next time), when the affinity rail has no definite `nextAt` for that bucket, the client SHALL render a horizontal progress bar in the region that would otherwise show the countdown or next-time chrome, and MUST show copy equivalent to「再有 x 条真实{事件名}记录后即可预估下次时间」, where x is `max(0, target − count)` and `{事件名}` is the display name for that card. When affinity produces a `nextAt`, the client MUST show the existing prediction/countdown UI and MUST NOT keep the progress bar alongside it.

无亲和 nextAt 时卡面 MUST 在原倒计时区展示横条进度与「再有 x 条…」文案；有 nextAt 时 MUST 恢复预测展示且 MUST NOT 并排进度。

#### Scenario: 差一条

- **WHEN** 有效发生 count=2 且 target=3 且无 nextAt
- **THEN** 文案中的 x MUST 为 1
- **AND** 进度条填充 MUST 约为 2/3

#### Scenario: 有预测则不显示进度

- **WHEN** 该桶亲和已产出 nextAt
- **THEN** 卡面 MUST 显示预测/倒计时
- **AND** MUST NOT 同时显示亲和进度条
