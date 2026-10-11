## ADDED Requirements

### Requirement: Client SHALL estimate active timing end from duration expect

When a catalog root has an in-progress `time` history record and the root’s duration expect line is confident (per `event-expect-prediction` / duration weighted median gate), the client SHALL compute `expectEndAt = startAt + expectDurationSec` using the active record’s start instant. When duration is not confident, the client MUST NOT invent an end estimate for that active record. Appointment roots and non-timing actives MUST NOT produce an active ETA.

进行中计时且 duration 有把握时 MUST 用 start+时长秒得 expectEndAt；无把握 MUST NOT 臆造；预约/非计时 MUST NOT 产出进行中 ETA。

#### Scenario: Confident duration yields end estimate

- **WHEN** 某根存在进行中计时且 duration 中位为 3900 秒、开始于 T0
- **THEN** 客户端 MUST 得到 expectEndAt = T0 + 3900 秒

#### Scenario: No duration confidence omits ETA

- **WHEN** 某根进行中但 duration 样本未过门闸
- **THEN** 客户端 MUST NOT 为该进行中记录产生 expectEndAt，且 MUST NOT 将其写入 active-eta 同步列表

### Requirement: Client SHALL sync active ETA list separately from imminent pending

The client SHALL full-replace sync the list of active ETAs to the twin Go App API (path per design; MUST NOT reuse `PUT /device/api/predict/imminent/pending`). Each item MUST include `rootEventId`, `leafEventId`, `startAt`, `expectEndAt`, and MAY include `historyId` and `title`. An empty list MUST clear server state. Sync MUST follow side-effect HTTP governance (single-flight, fingerprint including ETA fields, failure cooldown) and SHOULD trigger after eligible local start/stop timing or local mutations that recompute duration while an active timing exists.

进行中 ETA MUST 走独立全量同步，不得复用 imminent pending；空列表清空；须含根/叶子与起止秒；遵守副作用 HTTP 治理。

#### Scenario: Start timing with ETA syncs item

- **WHEN** 用户本机开始计时且该根 duration 有把握并触发同步
- **THEN** PUT body items MUST 含对应 leaf/root 与正 startAt/expectEndAt

#### Scenario: Stop timing clears or omits item

- **WHEN** 用户本机停止该计时后触发同步且无其它进行中 ETA
- **THEN** PUT body items MUST 为空数组以清空服务端

#### Scenario: Not merged into imminent pending

- **WHEN** 客户端同步进行中 ETA
- **THEN** 请求 MUST NOT 发往 imminent pending 路径作为唯一载体
