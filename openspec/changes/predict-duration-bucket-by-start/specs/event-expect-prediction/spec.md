## MODIFIED Requirements

### Requirement: Client SHALL compute dual-modal expect under each prediction root

The Flutter client SHALL, for each non-appointment catalog root that participates in interval prediction, separately compute a **duration** expect and an **amount** expect from real history under that root (home∪range; MUST NOT use recall-seed synthetics). Duration samples MUST be finished timing records (`eventNumber==0` with valid `endTime>startTime`) whose catalog leaf `eventType` is NOT `one`; the sample value MUST be duration in seconds. For each duration sample, the timestamp used for time-of-day bucket weighting and age-based recency MUST be that record’s **startTime** (MUST NOT use endTime for those weights). Amount samples MUST be metering records with `eventNumber>0` whose catalog leaf `eventType` is `number` (MUST NOT include `one` or `time`); the sample value MUST be that quantity. When a record’s leaf cannot be resolved in the catalog or has a missing/unknown `eventType`, the client MUST NOT treat it as `one` solely for exclusion (MAY still classify by payload modality as today). Each line MUST use a weighted median with the same time-of-day bucket weights and age-based recency half-life as interval prediction (applied to the sample timestamps defined above). A line MUST be considered confident only when it has at least 2 valid weighted samples. Failure of either expect line MUST NOT by itself remove a valid `nextAt` prediction. Appointment roots MUST NOT emit expect fields. Roots or histories that only yield `one` countable occurrences MUST NOT emit expect fields.

客户端 MUST 对非预约根并行计算 duration / amount 两条量线（真历史、禁种子）；duration 样本排除目录 `eventType=one`；duration 的时段桶与半衰期锚点 MUST 为该次计时 **startTime**（不得用 endTime 作加权时刻）；amount 样本仅计 `eventType=number`；各线加权中位与间隔侧桶/半衰期机制一致；≥2 有效样本才算有把握；量线失败不得单独取消 `nextAt`；预约根与仅 one 历史 MUST NOT 产出 expect。

#### Scenario: Duration line from finished timing

- **WHEN** 某非预约根下至少有 2 条已结束计时真记录（叶子非 one）且加权样本达标
- **THEN** 客户端 MUST 产出该根的 duration 期望秒数（加权中位）

#### Scenario: Duration weights use startTime not endTime

- **WHEN** 存在一条已结束计时 start=21:00、end=07:00（次日）
- **THEN** 该 duration 样本用于时段桶与半衰期的时刻 MUST 为 21:00（开始），MUST NOT 为 07:00（结束）

#### Scenario: Evening anchor prefers overnight starts over day naps by end

- **WHEN** 根下同时有夜间长睡（晚间 start、清晨 end）与日间短睡，且当前加权锚点为晚间 start（如进行中 21:00 开睡或等价锚点）
- **THEN** 在严格时段桶模式下，该夜间长睡样本的时段权重 MUST 不低于同根日间短睡样本（不得因清晨 end 被系统性降为远桶）

#### Scenario: Amount line from number records

- **WHEN** 某非预约根下至少有 2 条 `eventType=number` 且 `eventNumber>0` 真记录且加权样本达标
- **THEN** 客户端 MUST 产出该根的 amount 期望值与可用单位

#### Scenario: One leaf records do not feed amount

- **WHEN** 某非预约根下仅有 `eventType=one` 真记录（即使 `eventNumber=1` 且次数≥2）
- **THEN** 客户端 MUST NOT 将该根的 amount 视为有把握，且 MUST NOT 附加任何 expect 字段

#### Scenario: Insufficient samples omit that line

- **WHEN** 某根 duration 有效样本不足 2
- **THEN** 该根 MUST NOT 将 duration 视为有把握（MAY 仍有 amount）

#### Scenario: Appointment root has no expect

- **WHEN** 根为预约事件且存在约定 `nextAt`
- **THEN** 客户端 MUST NOT 为该根附加 expectKind / 用量 / 用时字段
