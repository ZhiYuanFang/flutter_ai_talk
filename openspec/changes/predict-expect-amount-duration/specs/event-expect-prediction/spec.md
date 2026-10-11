## ADDED Requirements

### Requirement: Client SHALL compute dual-modal expect under each prediction root

The Flutter client SHALL, for each non-appointment catalog root that participates in interval prediction, separately compute a **duration** expect and an **amount** expect from real history under that root (home∪range; MUST NOT use recall-seed synthetics). Duration samples MUST be finished `time` records (`eventNumber==0` with valid `endTime>startTime`); the sample value MUST be duration in seconds. Amount samples MUST be `number` records with `eventNumber>0`; the sample value MUST be that quantity. Each line MUST use a weighted median with the same time-of-day bucket weights and age-based recency half-life as interval prediction. A line MUST be considered confident only when it has at least 2 valid weighted samples. Failure of either expect line MUST NOT by itself remove a valid `nextAt` prediction. Appointment roots MUST NOT emit expect fields.

客户端 MUST 对非预约根并行计算 duration / amount 两条量线（真历史、禁种子）；各线加权中位与间隔侧桶/半衰期一致；≥2 有效样本才算有把握；量线失败不得单独取消 `nextAt`；预约根 MUST NOT 产出 expect。

#### Scenario: Duration line from finished timing

- **WHEN** 某非预约根下至少有 2 条已结束计时真记录且加权样本达标
- **THEN** 客户端 MUST 产出该根的 duration 期望秒数（加权中位）

#### Scenario: Amount line from number records

- **WHEN** 某非预约根下至少有 2 条 `eventNumber>0` 真记录且加权样本达标
- **THEN** 客户端 MUST 产出该根的 amount 期望值与可用单位

#### Scenario: Insufficient samples omit that line

- **WHEN** 某根 duration 有效样本不足 2
- **THEN** 该根 MUST NOT 将 duration 视为有把握（MAY 仍有 amount）

#### Scenario: Appointment root has no expect

- **WHEN** 根为预约事件且存在约定 `nextAt`
- **THEN** 客户端 MUST NOT 为该根附加 expectKind / 用量 / 用时字段

### Requirement: Client SHALL select at most one expect via latest countable modality

When presenting or syncing expect for a root, the client MUST expose at most one winning expect. When exactly one of duration/amount is confident, that line MUST win. When both are confident, the client MUST select the modality of the latest **countable** real occurrence under that root (finished time → duration; number with quantity>0 → amount). If the latest modality’s line is not confident, the client MUST fall back to the other confident line if any; if neither is confident, the client MUST omit expect entirely.

展示与同步 MUST 至多一条胜出 expect；仅一条有把握则取之；双线有把握则取最近可计量模态；该线无把握则回退另一条；皆无则省略。

#### Scenario: Only duration confident

- **WHEN** duration 有把握且 amount 无把握
- **THEN** 胜出 expectKind MUST 为 `duration`

#### Scenario: Both confident — latest is formula feed

- **WHEN** 双线均有把握，且该根最近可计量真记录为配方奶 number
- **THEN** 胜出 expectKind MUST 为 `amount`

#### Scenario: Both confident — latest is sleep timing

- **WHEN** 双线均有把握，且该根最近可计量真记录为已结束睡眠计时
- **THEN** 胜出 expectKind MUST 为 `duration`

#### Scenario: Neither confident

- **WHEN** duration 与 amount 均未过门闸
- **THEN** 客户端 MUST NOT 在预测模型或 pending 中附带 expect 字段

### Requirement: Client SHALL format expect copy with unified 约

Card secondary copy and the expect suffix semantics supplied to the server MUST use the unified wording particle「约」(MUST NOT use「需要」). Duration copy MUST follow existing Chinese duration formatting used for today-totals / history (hours and minutes; sub-minute as「不足1分钟」). Amount copy MUST be `{quantity}{unit}` with optional leaf title when the latest amount sample’s event name differs from the root title. Pending MUST send structured fields (`expectKind`, and either `expectDurationSec` or `expectAmount`/`expectUnit`/`expectLeafTitle`) rather than a prebuilt full push alert body.

卡片与供服务端拼接的语义 MUST 统一用「约」不得用「需要」；pending MUST 传结构化字段而非完整推送正文。

#### Scenario: Duration card line

- **WHEN** 胜出为 duration 且中位为 3900 秒
- **THEN** 卡片次级文案 MUST 匹配「预计约1小时5分钟」语义（允许与实现格式函数一致的空格差异）

#### Scenario: Amount with leaf title for pending

- **WHEN** 胜出为 amount=120、unit=毫升、叶子名=配方奶
- **THEN** pending 体 MUST 含 `expectKind=amount`、`expectAmount` 反映 120、`expectUnit=毫升`、`expectLeafTitle=配方奶`
