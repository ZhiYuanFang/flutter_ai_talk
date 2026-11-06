## MODIFIED Requirements

### Requirement: Client SHALL infer next event time from weighted interval history

The Flutter client SHALL compute a predicted next occurrence time (`nextAt`) per catalog root using the single formula `nextAt = lastAt + interval`. The `lastAt` MUST be the latest real feeding occurrence under that root, resolved from home and/or prediction-range history, or—when the window yields no occurrence—from the device-scoped event-last-at cache of previously observed real occurrences for that root (excluding recall-seed synthetics in all cases). The client MUST NOT inject recall-seed synthetic `HistoryRecord`s into the interval-statistics or prediction pipeline, and MUST NOT synthesize pseudo history rows from the last-at cache solely to satisfy the sample gate. For every real record that participates in interval statistics or as `lastAt` (including finished timing with `eventNumber==0`, in-progress timing when included, `one`, and `number`), the occurrence instant MUST be `startTime`, falling back to `createdAt` when `startTime` is missing. The client MUST NOT use `endTime` as the occurrence instant for interval prediction or `lastAt`.

When real samples meet the weighted-interval sample gate, `interval` MUST be the weighted median of real inter-occurrence deltas. Each eligible delta (≥ 15 minutes) MUST receive a weight equal to a **time-of-day affinity** factor times the existing recency weight with age-adjusted half-life. The affinity factor MUST be a decreasing function of the circular local-clock distance (minutes on a 24-hour ring, capped at 12 hours) between the delta’s **start** instant and `lastAt`. Samples whose affinity factor is below a small positive cutoff MUST be excluded. The client MUST NOT use the legacy six wall-clock buckets or the same-bucket → adjacent → all-buckets stepwise set selection as the primary voting path. When at least 2 affinity-eligible weighted samples remain, the client MUST use their weighted median as `interval`. When fewer than 2 remain but a persisted `PredictionRecallSeed` with a valid `interval` (≥ 15 minutes) exists for that root AND a real `lastAt` exists (window or cache), `interval` MUST be `seed.interval`. When real `lastAt` is missing, OR both the sample gate fails and no valid seed interval applies, the event MUST be unpredictable and MUST NOT appear as a predict row / card countdown. The client MUST NOT call backend APIs solely for widget prediction. The client MUST NOT use `PredictionRecallSeed.lastAt` as the prediction anchor when real `lastAt` (window or cache) is missing. Any `nextAt` produced by this requirement remains subject to the historical time-of-day density guard requirement in this capability when that guard is active.

客户端 MUST 用单一公式 `nextAt = lastAt + interval` 推断各目录根下次时刻；`lastAt` MUST 为真喂养最新发生（home 与/或预测 range，窗口未命中时 MUST 可回退 device 维度事件最近发生缓存；排除回忆种子伪记录）；MUST NOT 将回忆种子或 lastAt 缓存合成为伪 `HistoryRecord` 进入间隔统计或凑样本门闸。凡参与间隔统计或作为 `lastAt` 的真记录，发生时刻 MUST 为 `startTime`，缺失时用 `createdAt`；MUST NOT 用 `endTime`。真样本达标时 `interval` MUST 为有效间隔的加权中位：权重 MUST 为**钟点亲和**（间隔起点与 `lastAt` 的本地 24h 环形分钟距离的递减函数）乘既有时间衰减与月龄半衰期；亲和低于截断阈值的样本 MUST 排除。MUST NOT 再以六时段桶及同档→相邻→全桶阶梯集合作为主投票路径。亲和有效样本不少于 2 时 MUST 用其加权中位；不足但有有效种子间隔且有真 `lastAt` 时 MUST 用 `seed.interval`；无真 `lastAt` 或两者皆失败时 MUST 不可预测。不得为小组件预测单独请求后端；无真 `lastAt` 时 MUST NOT 用种子 `lastAt` 作锚点。所得 `nextAt` 在护栏启用时 MUST 再受本能力「历史钟点密度护栏」约束。

#### Scenario: 使用发生时刻构建间隔

- **WHEN** 预测模块处理 `one`、`number` 或已结束的 `time` 类型真记录
- **THEN** 发生时刻 MUST 取 `startTime`，缺失时用 `createdAt`
- **AND** MUST NOT 用 `endTime` 作为间隔或 `lastAt` 的发生锚点

#### Scenario: 过滤过短间隔

- **WHEN** 相邻两次真发生间隔小于 15 分钟
- **THEN** 该间隔 MUST NOT 参与加权统计

#### Scenario: 钟点更近的间隔权重大于更远的间隔

- **WHEN** 某根 `lastAt` 约为本地 19:55，历史中同时存在起点约 19:50 的长间隔与起点约 18:00 的短间隔，且二者均 ≥15 分钟
- **THEN** 客户端 MUST 给起点更接近 `lastAt` 的间隔更高的钟点亲和权重
- **AND** MUST NOT 仅因二者曾同属旧「18 点后」粗桶而赋予相等时段权重

#### Scenario: 低亲和样本不计入中位

- **WHEN** 某间隔起点与 `lastAt` 的环形钟点距离使亲和因子低于实现截断阈值
- **THEN** 该间隔 MUST NOT 进入加权中位集合

#### Scenario: 亲和有效样本不少于 2 时用加权中位

- **WHEN** 截断后仍有不少于 2 条带正权重的真间隔
- **THEN** 客户端 MUST 以这些样本的加权中位数为 `interval` 并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 使用回忆种子间隔覆盖该中位数

#### Scenario: 日末锚点不被远处白天短间隔主导

- **WHEN** `lastAt` 落在该事件习惯日末附近，且与 `lastAt` 钟点接近的间隔明显长于钟点远离的白天短间隔
- **THEN** 客户端 MUST 以亲和加权后的中位计算 `nextAt`
- **AND** MUST NOT 因远处白天短间隔条数更多而把 `nextAt` 落在 `lastAt` 之后仅一个短间隔处

#### Scenario: 亲和有效样本不足时使用种子间隔

- **WHEN** 某根亲和有效真样本少于 2，且存在有效 `PredictionRecallSeed.interval`，且该根有真 `lastAt`（窗口或事件最近发生缓存）
- **THEN** 客户端 MUST 以 `seed.interval` 为间隔并计算 `nextAt = lastAt + interval`
- **AND** MUST NOT 依赖种子合成伪记录条数来满足样本门闸

#### Scenario: 样本不足且无种子

- **WHEN** 某根亲和有效真样本不足且无有效种子间隔
- **THEN** 该事件 MUST 标记为不可预测且 MUST NOT 出现在 predict 行

#### Scenario: 无真 lastAt 不预测

- **WHEN** 某根在 home∪range 与事件最近发生缓存中均无法解析发生时刻
- **THEN** 客户端 MUST NOT 产出该根预测
- **AND** MUST NOT 使用 `PredictionRecallSeed.lastAt` 作为推演锚点

#### Scenario: 窗口未命中但缓存有 lastAt 且有种子

- **WHEN** 某根 home∪range 无真发生，事件最近发生缓存有时刻 T，且存在有效 `PredictionRecallSeed.interval`
- **THEN** 客户端 MUST 以 `lastAt = T` 与 `seed.interval` 计算 `nextAt`
- **AND** MUST NOT 为凑样本门闸而把 T 写成伪 `HistoryRecord`

#### Scenario: 禁止种子伪历史进入推演

- **WHEN** 存在回忆种子合成记录
- **THEN** 间隔统计与 `lastAt` 解析 MUST NOT 计入这些伪记录

#### Scenario: 禁止六桶阶梯主路径

- **WHEN** 客户端计算非预约根的间隔中位
- **THEN** MUST NOT 再以「同档桶样本 ≥2 则只用同档、否则相邻、否则全桶等权」作为主投票路径

## ADDED Requirements

### Requirement: Client SHALL guard nextAt with a per-root historical time-of-day histogram

After a candidate `nextAt` is computed for a non-appointment catalog root (from affinity-weighted median or seed interval), when the root has at least a configured minimum number of real historical occurrences (default **7**) usable for density, the client MUST evaluate the local clock time of `nextAt` against a **circular daily histogram** built from that root’s real occurrence clock times (same occurrence instant rules as interval prediction; excluding recall-seed synthetics). The histogram MUST use fixed-width bins covering 24 local hours (default **30-minute** bins). The client MAY smooth each bin with its circular neighbors. The client MUST compute a relative score of the bin containing `nextAt` (after optional smoothing) divided by the maximum bin score on that root. When the relative score is below a configured threshold (default **0.2**), the client MUST reject that candidate `nextAt`. On rejection, the client MUST attempt at most the following fallbacks in order, re-checking the histogram each time: (1) weighted median of affinity-eligible samples whose duration is ≥ the primary median, when at least 2 such samples exist; (2) weighted median of affinity-eligible samples that cross a local calendar day boundary, when at least 2 such samples exist. If no fallback candidate passes the guard, the root MUST be unpredictable for this computation (MUST NOT keep the rejected cold-zone `nextAt`). When the root has fewer than the minimum occurrences for density, the client MUST NOT apply this guard (MUST NOT reject solely for density). The client MUST NOT use a globally hard-coded clock cutoff such as 「after 20:00」to implement this guard.

非预约根在得出候选 `nextAt`（亲和中位或种子间隔）后，当该根可用于密度的真发生次数不少于配置下限（默认 7）时，客户端 MUST 用该根真发生本地钟点构建**环形日直方图**（默认 30 分钟一格，MAY 邻格平滑；发生时刻规则与间隔预测一致，排除回忆种子），并计算 `nextAt` 所在格相对峰值的比值；低于阈值（默认 0.2）MUST 拒绝该候选。拒绝后 MUST 按序尝试：（1）亲和有效且时长 ≥ 主中位的样本中位（≥2 条）；（2）亲和有效且跨本地自然日的样本中位（≥2 条）；每次再过护栏。皆失败则本根本次 MUST 不可预测，MUST NOT 保留冷区 `nextAt`。发生次数不足下限时 MUST NOT 启用本护栏。MUST NOT 用全局写死钟点（如「20:00 后」）实现本护栏。

#### Scenario: 冷区 nextAt 被拒绝

- **WHEN** 某根历史发生钟点几乎都在日间至傍晚热区，且亲和/种子算出的 `nextAt` 落在历史相对峰值 &lt; 阈值的深夜/凌晨格，且该根真发生数 ≥ 密度下限
- **THEN** 客户端 MUST 拒绝该候选 `nextAt`
- **AND** MUST NOT 因全局写死「20 点后」规则而拒绝（仅因该根直方图）

#### Scenario: 拒绝后跨日长间隔候选可通过

- **WHEN** 主中位 `nextAt` 因直方图护栏被拒，且亲和有效样本中存在不少于 2 条跨本地自然日的间隔，其加权中位对应的 `nextAt` 落在热区
- **THEN** 客户端 MUST 可采用该跨日候选作为预测结果

#### Scenario: 护栏与回退皆失败则不可预测

- **WHEN** 主候选与设计允许的回退候选均未通过直方图护栏
- **THEN** 该根 MUST 不可预测且 MUST NOT 展示被拒的冷区 `nextAt`

#### Scenario: 样本过少不启用护栏

- **WHEN** 某根真发生次数低于密度下限
- **THEN** 客户端 MUST NOT 仅因直方图相对峰值而拒绝 `nextAt`
