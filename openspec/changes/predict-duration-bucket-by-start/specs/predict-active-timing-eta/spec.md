## MODIFIED Requirements

### Requirement: Client SHALL estimate active timing end from duration expect

When a catalog root has an in-progress `time` history record and the root’s duration expect line is confident (per `event-expect-prediction` / duration weighted median gate, including duration sample timestamps anchored at **startTime**), the client SHALL compute `expectEndAt = startAt + expectDurationSec` using the active record’s start instant. When duration is not confident, the client MUST NOT invent an end estimate for that active record. Appointment roots and non-timing actives MUST NOT produce an active ETA.

进行中计时且 duration 有把握时 MUST 用 start+时长秒得 expectEndAt；duration 加权 MUST 遵循 start 锚点规则；无把握 MUST NOT 臆造；预约/非计时 MUST NOT 产出进行中 ETA。

#### Scenario: Confident duration yields end estimate

- **WHEN** 某根存在进行中计时且 duration 中位为 3900 秒、开始于 T0
- **THEN** 客户端 MUST 得到 expectEndAt = T0 + 3900 秒

#### Scenario: Evening active timing uses overnight-start-weighted duration

- **WHEN** 用户于晚间开始睡眠计时，且根下夜间长睡（晚间 start）与日间短睡均足以参与加权
- **THEN** 用于 expectEndAt 的 durationSec MUST 来自按 startTime 分桶/半衰期的 duration 线（不得仍按 endTime 分桶以致系统性地贴近日间短睡中位）

#### Scenario: No duration confidence omits ETA

- **WHEN** 某根进行中但 duration 样本未过门闸
- **THEN** 客户端 MUST NOT 为该进行中记录产生 expectEndAt，且 MUST NOT 将其写入 active-eta 同步列表
