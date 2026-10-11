## ADDED Requirements

### Requirement: Pending sync SHALL include winning expect structured fields

When the client performs `PUT /device/api/predict/imminent/pending` after an eligible local mutation, each event item that has a winning expect MUST include structured fields aligned with the twin Go contract: `expectKind` (`duration` or `amount`), and for duration `expectDurationSec` (>0), or for amount `expectAmount` (>0) with optional `expectUnit` and `expectLeafTitle`. Events without a winning expect MUST omit these fields (MUST NOT send zero/empty placeholders that imply a prediction). The client MUST NOT send a fully composed push alert string as a substitute for these fields. Existing requirements for full-replace sync triggers, empty clear, appointment omission, and no-sync-on-pull/WS SHALL remain.

合格本机变更后的 pending 同步中，有胜出 expect 的项 MUST 带结构化字段；无胜出 MUST 省略；MUST NOT 用整句 alert 代替；既有同步触发与清空语义不变。

#### Scenario: Duration expect in pending body

- **WHEN** 某根预测有 `nextAt` 且胜出 duration=3900 秒并触发 pending 同步
- **THEN** 请求体该事件 MUST 含 `expectKind` 为 `duration` 且 `expectDurationSec` 为 3900（或等价正秒）

#### Scenario: Amount expect in pending body

- **WHEN** 某根预测有 `nextAt` 且胜出 amount=120 毫升配方奶并触发 pending 同步
- **THEN** 请求体该事件 MUST 含 `expectKind=amount`、反映 120 的 `expectAmount`、`expectUnit` 含毫升语义，且 `expectLeafTitle` 为配方奶（当叶子名与根名不同时）

#### Scenario: No expect fields when unconfident

- **WHEN** 某根仅有 `nextAt`、无胜出 expect 并触发 pending 同步
- **THEN** 该事件 JSON MUST NOT 包含表示已预测用量/用时的 expect 字段

### Requirement: Pending sync fingerprint SHALL include expect

The client-side dedupe fingerprint used to skip redundant pending HTTP MUST incorporate the winning expect identity (kind and numeric/unit/leaf payload), not only `eventId` and `nextAt`. When expect changes while `nextAt` is unchanged, the client MUST still attempt pending sync (subject to existing login/cooldown/single-flight rules).

指纹 MUST 含 expect；仅 expect 变化时 MUST 仍尝试同步（仍受既有登录/熔断/single-flight 约束）。

#### Scenario: Expect-only change resyncs

- **WHEN** 同一 `eventId` 与 `nextAt` 下胜出用量从 100 变为 120 且触发合格本机变更同步路径
- **THEN** 客户端 MUST NOT 因 `eventId:nextAt` 指纹相同而跳过本次 pending PUT
