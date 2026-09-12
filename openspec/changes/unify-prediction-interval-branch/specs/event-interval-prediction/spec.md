## MODIFIED Requirements

### Requirement: Client SHALL infer next event time from weighted interval history

The Flutter client SHALL compute a predicted next occurrence time (`nextAt`) per catalog root using the single formula `nextAt = lastAt + interval`. The `lastAt` MUST be the latest real feeding occurrence under that root (from home and/or prediction-range history, excluding recall-seed synthetics). The client MUST NOT inject recall-seed synthetic `HistoryRecord`s into the interval-statistics or prediction pipeline. When real samples meet the weighted-interval sample gate, `interval` MUST be the existing weighted-median of real inter-occurrence deltas (time-of-day bucketing, recency weighting, age-adjusted half-life). When the sample gate is not met but a persisted `PredictionRecallSeed` with a valid `interval` (≥ 15 minutes) exists for that root AND a real `lastAt` exists, `interval` MUST be `seed.interval`. When real `lastAt` is missing, OR both the sample gate fails and no valid seed interval applies, the event MUST be unpredictable and MUST NOT appear as a predict row / card countdown. The client MUST NOT call backend APIs solely for widget prediction.

客户端 MUST 用单一公式 `nextAt = lastAt + interval` 推断各目录根下次时刻；`lastAt` MUST 仅为真喂养最新发生（home 与/或预测 range，排除回忆种子伪记录）；MUST NOT 将回忆种子合成为伪 `HistoryRecord` 进入间隔统计或推演。真样本达标时 `interval` MUST 为既有加权中位（分时段桶、时间衰减、月龄半衰期）；未达标但该根有有效种子间隔且存在真 `lastAt` 时，`interval` MUST 为 `seed.interval`；无真 `lastAt`，或未达标且无有效种子间隔时，该事件 MUST 不可预测且 MUST NOT 出现在 predict 行。不得为小组件预测单独请求后端。

#### Scenario: 使用发生时刻构建间隔

- **WHEN** 预测模块处理 `one` 或 `number` 类型真记录
- **THEN** 发生时刻 MUST 取 `startTime`，缺失时用 `createdAt`
- **WHEN** 预测模块处理已结束的 `time` 类型真记录
- **THEN** 发生时刻 MUST 取 `endTime`

#### Scenario: 过滤过短间隔

- **WHEN** 相邻两次真发生间隔小于 15 分钟
- **THEN** 该间隔 MUST NOT 参与加权统计

#### Scenario: 加权中位数与样本充足

- **WHEN** 某根在同锚点时段桶（及相邻桶）下有效真间隔样本不少于 2
- **THEN** 客户端 MUST 使用加权中位数作为典型间隔并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 使用回忆种子间隔覆盖该中位数

#### Scenario: 样本不足时使用种子间隔

- **WHEN** 某根真样本不足以完成加权中位，且存在有效 `PredictionRecallSeed.interval`，且该根有真 `lastAt`
- **THEN** 客户端 MUST 以 `seed.interval` 为间隔并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 依赖种子合成伪记录条数来满足样本门闸

#### Scenario: 样本不足且无种子

- **WHEN** 某根真样本不足且无有效种子间隔
- **THEN** 该事件 MUST 标记为不可预测且 MUST NOT 出现在 predict 行

#### Scenario: 无真 lastAt 不预测

- **WHEN** 某根在真喂养历史中无法解析发生时刻（含该根记录已全部删除）
- **THEN** 客户端 MUST NOT 产出该根预测
- **AND** MUST NOT 使用 `PredictionRecallSeed.lastAt` 作为推演锚点

#### Scenario: 禁止种子伪历史进入推演

- **WHEN** 本地存在某根的 `PredictionRecallSeed`
- **THEN** 客户端 MUST NOT 将其 `occurrenceAts` 合成为参与 `predictAllUpcoming` / 等价推演的 `HistoryRecord`
