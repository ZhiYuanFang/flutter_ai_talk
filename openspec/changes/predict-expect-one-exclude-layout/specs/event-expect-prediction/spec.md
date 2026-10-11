## MODIFIED Requirements

### Requirement: Client SHALL compute dual-modal expect under each prediction root

The Flutter client SHALL, for each non-appointment catalog root that participates in interval prediction, separately compute a **duration** expect and an **amount** expect from real history under that root (home∪range; MUST NOT use recall-seed synthetics). Duration samples MUST be finished timing records (`eventNumber==0` with valid `endTime>startTime`) whose catalog leaf `eventType` is NOT `one`; the sample value MUST be duration in seconds. Amount samples MUST be metering records with `eventNumber>0` whose catalog leaf `eventType` is `number` (MUST NOT include `one` or `time`); the sample value MUST be that quantity. When a record’s leaf cannot be resolved in the catalog or has a missing/unknown `eventType`, the client MUST NOT treat it as `one` solely for exclusion (MAY still classify by payload modality as today). Each line MUST use a weighted median with the same time-of-day bucket weights and age-based recency half-life as interval prediction. A line MUST be considered confident only when it has at least 2 valid weighted samples. Failure of either expect line MUST NOT by itself remove a valid `nextAt` prediction. Appointment roots MUST NOT emit expect fields. Roots or histories that only yield `one` countable occurrences MUST NOT emit expect fields.

客户端 MUST 对非预约根并行计算 duration / amount 两条量线（真历史、禁种子）；duration 样本排除目录 `eventType=one`；amount 样本仅计 `eventType=number`（MUST NOT 纳入 one）；各线加权中位与间隔侧桶/半衰期一致；≥2 有效样本才算有把握；量线失败不得单独取消 `nextAt`；预约根与仅 one 历史 MUST NOT 产出 expect。

#### Scenario: Duration line from finished timing

- **WHEN** 某非预约根下至少有 2 条已结束计时真记录（叶子非 one）且加权样本达标
- **THEN** 客户端 MUST 产出该根的 duration 期望秒数（加权中位）

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

### Requirement: Client SHALL select at most one expect via latest countable modality

When presenting or syncing expect for a root, the client MUST expose at most one winning expect. A real occurrence is **countable** for modality only when it qualifies as a duration or amount sample under the dual-modal rules above (finished non-`one` timing → duration; `eventType=number` with quantity>0 → amount). `eventType=one` occurrences MUST NOT participate in latest-modality selection. When exactly one of duration/amount is confident, that line MUST win. When both are confident, the client MUST select the modality of the latest countable real occurrence under that root. If the latest modality’s line is not confident, the client MUST fall back to the other confident line if any; if neither is confident, the client MUST omit expect entirely.

展示与同步 MUST 至多一条胜出 expect；one 不得参与可计量模态；仅一条有把握则取之；双线有把握则取最近可计量模态；该线无把握则回退另一条；皆无则省略。

#### Scenario: Only duration confident

- **WHEN** duration 有把握且 amount 无把握
- **THEN** 胜出 expectKind MUST 为 `duration`

#### Scenario: Both confident — latest is formula feed

- **WHEN** 双线均有把握，且该根最近可计量真记录为配方奶 number
- **THEN** 胜出 expectKind MUST 为 `amount`

#### Scenario: Both confident — latest is sleep timing

- **WHEN** 双线均有把握，且该根最近可计量真记录为已结束睡眠计时
- **THEN** 胜出 expectKind MUST 为 `duration`

#### Scenario: Latest one occurrence ignored for modality

- **WHEN** 双线均有把握，且时间上最近的真记录为 `eventType=one`，其前一条可计量为 number
- **THEN** 胜出 expectKind MUST 为 `amount`（MUST NOT 因该 one 记录取消或改写胜出）

#### Scenario: Neither confident

- **WHEN** duration 与 amount 均未过门闸
- **THEN** 客户端 MUST NOT 在预测模型或 pending 中附带 expect 字段
