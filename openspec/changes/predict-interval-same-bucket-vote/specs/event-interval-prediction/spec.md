## MODIFIED Requirements

### Requirement: Client SHALL infer next event time from weighted interval history

The Flutter client SHALL compute a predicted next occurrence time (`nextAt`) per catalog root using the single formula `nextAt = lastAt + interval`. The `lastAt` MUST be the latest real feeding occurrence under that root, resolved from home and/or prediction-range history, or—when the window yields no occurrence—from the device-scoped event-last-at cache of previously observed real occurrences for that root (excluding recall-seed synthetics in all cases). The client MUST NOT inject recall-seed synthetic `HistoryRecord`s into the interval-statistics or prediction pipeline, and MUST NOT synthesize pseudo history rows from the last-at cache solely to satisfy the sample gate. When real samples meet the weighted-interval sample gate, `interval` MUST be the weighted median of real inter-occurrence deltas with recency weighting and age-adjusted half-life, using time-of-day buckets of each delta's start. The client MUST prefer deltas whose start bucket equals the anchor bucket of `lastAt`: when that same-bucket set has at least 2 samples, the median MUST use only that set (bucket weight 1) and MUST NOT include adjacent or farther buckets. When the same-bucket set has fewer than 2 samples but the same-or-adjacent set has at least 2, the median MUST use that same-or-adjacent set (same-bucket weight 1, adjacent weight 0.6). When that set also has fewer than 2 samples, the client MUST fall back to all buckets at equal bucket weight, and use that median only when it has at least 2 samples. When the sample gate is not met but a persisted `PredictionRecallSeed` with a valid `interval` (≥ 15 minutes) exists for that root AND a real `lastAt` exists (window or cache), `interval` MUST be `seed.interval`. When real `lastAt` is missing, OR both the sample gate fails and no valid seed interval applies, the event MUST be unpredictable and MUST NOT appear as a predict row / card countdown. The client MUST NOT call backend APIs solely for widget prediction. The client MUST NOT use `PredictionRecallSeed.lastAt` as the prediction anchor when real `lastAt` (window or cache) is missing.

客户端 MUST 用单一公式 `nextAt = lastAt + interval` 推断各目录根下次时刻；`lastAt` MUST 为真喂养最新发生（home 与/或预测 range，窗口未命中时 MUST 可回退 device 维度事件最近发生缓存；排除回忆种子伪记录）；MUST NOT 将回忆种子或 lastAt 缓存合成为伪 `HistoryRecord` 进入间隔统计或凑样本门闸。真样本达标时 `interval` MUST 为按间隔起点时段桶与时间衰减、月龄半衰期得到的加权中位：起点与 `lastAt` 锚点桶相同的样本不少于 2 时，中位 MUST 只用该同档集合（桶权重 1），MUST NOT 纳入相邻或更远桶；同档不足 2 但同档加相邻不少于 2 时，MUST 用该集合（同档 1、相邻 0.6）；该集合仍不足 2 时 MUST 回退全桶等权，且仅当全桶不少于 2 时采用该中位。未达标但该根有有效种子间隔且存在真 `lastAt`（窗或缓存）时，`interval` MUST 为 `seed.interval`；无真 `lastAt`，或未达标且无有效种子间隔时，该事件 MUST 不可预测且 MUST NOT 出现在 predict 行。不得为小组件预测单独请求后端；无真 `lastAt` 时 MUST NOT 用 `PredictionRecallSeed.lastAt` 作锚点。

#### Scenario: 使用发生时刻构建间隔

- **WHEN** 预测模块处理 `one` 或 `number` 类型真记录
- **THEN** 发生时刻 MUST 取 `startTime`，缺失时用 `createdAt`
- **WHEN** 预测模块处理已结束的 `time` 类型真记录
- **THEN** 发生时刻 MUST 取 `endTime`

#### Scenario: 过滤过短间隔

- **WHEN** 相邻两次真发生间隔小于 15 分钟
- **THEN** 该间隔 MUST NOT 参与加权统计

#### Scenario: 同档样本不少于 2 时只投同档

- **WHEN** 某根 `lastAt` 所在时段桶内、起点落在同一桶的有效真间隔不少于 2，且其它桶还有更多更短间隔
- **THEN** 客户端 MUST 只用同档间隔的加权中位数作为典型间隔并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 把相邻桶或更远桶的间隔计入该中位数
- **AND** MUST NOT 使用回忆种子间隔覆盖该中位数

#### Scenario: 傍晚锚点的过夜间隔不被白天短间隔压过

- **WHEN** 上次真发生在 18 点及以后的时段桶，同桶起点的间隔不少于 2 且这些间隔明显长于白天其它桶的间隔
- **THEN** 客户端 MUST 以同桶间隔的加权中位数计算 `nextAt`
- **AND** MUST NOT 因白天短间隔条数更多而把 `nextAt` 落在 `lastAt` 之后仅一个短间隔处

#### Scenario: 清晨锚点不被过夜长间隔拉长

- **WHEN** 上次真发生在清晨时段桶，同桶起点的较短间隔不少于 2，且历史中另有过夜长间隔
- **THEN** 客户端 MUST 只用清晨同桶间隔的加权中位数
- **AND** MUST NOT 把过夜长间隔计入该中位数

#### Scenario: 同档不足时使用相邻档

- **WHEN** 同锚点时段桶的有效真间隔少于 2，且同桶与相邻桶合计不少于 2
- **THEN** 客户端 MUST 使用同桶与相邻桶样本的加权中位数（同桶权重 1、相邻权重 0.6，再乘时间衰减）并计算 `nextAt = lastAt + interval`

#### Scenario: 相邻档仍不足时全桶等权

- **WHEN** 同桶与相邻桶合计少于 2，且全部时段桶的有效真间隔不少于 2
- **THEN** 客户端 MUST 使用全桶等权（桶权重均为 1，再乘时间衰减）的加权中位数并计算 `nextAt = lastAt + interval`

#### Scenario: 样本不足时使用种子间隔

- **WHEN** 某根真样本不足以完成加权中位，且存在有效 `PredictionRecallSeed.interval`，且该根有真 `lastAt`（窗口或事件最近发生缓存）
- **THEN** 客户端 MUST 以 `seed.interval` 为间隔并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 依赖种子合成伪记录条数来满足样本门闸

#### Scenario: 样本不足且无种子

- **WHEN** 某根真样本不足且无有效种子间隔
- **THEN** 该事件 MUST 标记为不可预测且 MUST NOT 出现在 predict 行

#### Scenario: 无真 lastAt 不预测

- **WHEN** 某根在 home∪range 与事件最近发生缓存中均无法解析发生时刻（含该根可见记录已全部删除且 tip 已失效）
- **THEN** 客户端 MUST NOT 产出该根预测
- **AND** MUST NOT 使用 `PredictionRecallSeed.lastAt` 作为推演锚点

#### Scenario: 窗口未命中但缓存有 lastAt 且有种子

- **WHEN** 某根 home∪range 无真发生，事件最近发生缓存有时刻 T，且存在有效 `PredictionRecallSeed.interval`
- **THEN** 客户端 MUST 以 `lastAt = T` 与 `seed.interval` 计算 `nextAt`
- **AND** MUST NOT 为凑样本门闸而把 T 写成伪 `HistoryRecord`

#### Scenario: 禁止种子伪历史进入推演

- **WHEN** 本地存在某根的 `PredictionRecallSeed`
- **THEN** 客户端 MUST NOT 将其 `occurrenceAts` 合成为参与 `predictAllUpcoming` / 等价推演的 `HistoryRecord`
