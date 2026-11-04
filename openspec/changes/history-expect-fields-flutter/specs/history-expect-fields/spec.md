## ADDED Requirements

### Requirement: Client SHALL stamp optional expect fields only on history add

On constructing a history **add** body for `POST /device/history/api/event/add` (via `buildEventAddBody` or equivalent), when a current prediction for that event is available, the client MUST set `expectStartTime` (unix seconds, JSON number) from that prediction’s `nextAt` even if `nextAt` is already in the past. When a duration expect is available and `expectStartTime` is set, the client MUST set `expectEndTime` to start plus duration seconds. When an amount expect is available, the client MUST set `expectAmount` as a **floating-point** JSON number (MUST NOT integer-truncate). When a dimension is unavailable, the client MUST omit that key (MUST NOT send a sentinel `0` solely to mean “absent”). The client MUST NOT include `expectStartTime`, `expectEndTime`, or `expectAmount` on timing **stop** or other history **update** bodies. User edits to actual times/amount MUST NOT recompute or resend `expect*`. Server persistence and update-freeze behavior are delivered by twin `go_ai_talk` / `history-expect-fields-go` (complete).

构造历史 **add** body 时，若该事件当前预报可用，客户端 MUST 将 `expectStartTime`（unix 秒）设为当时 `nextAt`（**含已过期**）。若有 duration expect 且已设 start，MUST 设 `expectEndTime = start + duration`。若有 amount expect，MUST 以 **浮点** JSON 数字设 `expectAmount`（MUST NOT 截断为整数）。某维不可用 MUST **省略该键**（MUST NOT 仅用 `0` 表示缺省）。计时 **停止** 与其它 **update** MUST NOT 包含三 expect 字段。用户改实际时间/用量 MUST NOT 重算或重传 expect*。服务端落库与 update 冻结见已完成 twin `history-expect-fields-go`。

#### Scenario: Add stamps overdue nextAt

- **WHEN** 用户 add 且当时预报 `nextAt` 早于现在
- **THEN** add body MUST 含 `expectStartTime` 等于该 `nextAt`（unix 秒）

#### Scenario: Add stamps expectAmount as float

- **WHEN** 用户 add 且当时存在 amount expect（例如 `120.5`）
- **THEN** add body MUST 含浮点 `expectAmount`
- **AND** MUST NOT 将其截断为整数 `120` 后上传

#### Scenario: Timing stop does not send expect fields

- **WHEN** 用户停止计时并 update `endTime`
- **THEN** update body MUST NOT 包含 `expectStartTime` / `expectEndTime` / `expectAmount`

#### Scenario: Add without prediction omits expect fields

- **WHEN** add 时无可用 `nextAt`
- **THEN** add body MUST NOT 要求包含任何 expect* 键

### Requirement: Local history cache SHALL preserve expect fields

The client MUST retain `expectStartTime` / `expectEndTime` / `expectAmount` inside `HistoryRecord.rawPayload` when ingesting server maps and MUST NOT strip them on WebSocket upsert/merge. Local persistence equality checks MUST treat changes to these keys as content changes. Values MUST round-trip types consistently with the server (times as int seconds; amount as num/double).

客户端解析服务端 map 时 MUST 保留 rawPayload 中的三 expect 键；WS upsert MUST NOT 剥除。磁盘相等性 MUST 将上述键变化视为内容变化。时间按整秒、用量按浮点与服务器一致往返。

#### Scenario: WS upsert keeps expectStartTime

- **WHEN** 记录含 `expectStartTime` 且 WS upsert 同 id 仍带该字段
- **THEN** 内存/磁盘 MUST 仍可读到 `expectStartTime`

#### Scenario: List round-trips expectAmount float

- **WHEN** list/WS 回传 `expectAmount` 为小数（如 `120.5`）
- **THEN** 本地 rawPayload MUST 可读出等价浮点（MUST NOT 仅保留截断整数）

### Requirement: Accuracy consumers SHALL use only rows with expect fields and MUST NOT replay

Downstream prediction-accuracy features MUST score only rows with usable stored `expect*` (at minimum usable `expectStartTime` unless narrowed later). The client MUST NOT synthesize historical `expect*` by replaying the interval algorithm on rows that lack these fields.

下游准确度 MUST 仅计有可用已存 `expect*` 的行；MUST NOT 对缺字段老行重放伪造 expect*。

#### Scenario: Legacy row without expect is not a score sample

- **WHEN** 记录三 expect 字段皆空
- **THEN** 准确度 MUST NOT 将其作对照样本
- **AND** MUST NOT 重放填假 expect*
