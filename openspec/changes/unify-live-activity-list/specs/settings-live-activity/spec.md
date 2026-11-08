## MODIFIED Requirements

### Requirement: Lock-screen status UI SHALL expose diagnosable registration stages

The lock-screen settings page MUST make it possible, without system logs, to distinguish at least: unsupported OS version for Push-to-Start, system Live Activities disallowed, listening not started / waiting for system token, whether a Push-to-Start **event was received** for the unified `BabyLiveActivityAttributes` versus whether `live-activity/register` **succeeded** for `tokenKind=push_to_start`, HTTP/register failures, and timeout-while-keeping-prior-success. The page MUST show a human-readable failure summary and MUST also expose a compact copyable diagnostic summary (OS major version, listening flag, optional native push-to-start deliver count, unified seen/ok flags, error category code). The client MUST NOT display the raw push token. When a retry ends in timeout, if an HTTP/register error was already recorded for that attempt, the client MUST NOT overwrite it with a generic 「waiting for system token」 message. 「已开通」MUST require successful unified Push-to-Start registration under the client's recorded success criteria (MUST NOT require both legacy `imminent` and `timing` attributes kinds).

锁屏通知页 MUST 可区分上述阶段（统一 Attributes 的 PTS 事件 vs register 成功、HTTP 失败、保留上次成功的超时）；MUST 提供人话失败摘要与可复制诊断摘要；MUST NOT 展示原始 token；本轮已有 HTTP 错误时 MUST NOT 被笼统「等系统 token」覆盖。「已开通」MUST 以统一轨 Push-to-Start 成功为准，MUST NOT 再要求双 attributesKind 均成功。

#### Scenario: Unified push-to-start registered

- **WHEN** 客户端已成功为统一 Attributes 完成 `tokenKind=push_to_start` 的 `live-activity/register`
- **AND** 系统允许 Live Activities 且系统版本支持 Push-to-Start
- **THEN** 页面 MUST 将锁屏通知展示为已开通（或等价绿态）

#### Scenario: HTTP register failure visible and not overwritten by timeout

- **WHEN** 用户触发手动重试且本轮已收到系统 token 但 `live-activity/register` 返回错误
- **THEN** 页面下方 MUST 展示可读的 HTTP/业务失败信息
- **AND** MUST NOT 展示完整 token 字符串
- **AND** 即使随后等待超时，MUST NOT 用「未收到系统 token」类文案覆盖该 HTTP 失败信息

#### Scenario: System token timeout when no token event

- **WHEN** 用户触发手动重试且在约定超时内未收到任何 Push-to-Start token 事件
- **THEN** 页面下方 MUST 展示表明未收到系统 token 的失败信息
- **AND** 可复制诊断摘要 MUST 能反映未见 PTS 事件（或原生 deliver 计数为 0，若可得）

#### Scenario: Copyable diagnostic summary

- **WHEN** 用户打开锁屏通知页或完成一次手动重试
- **THEN** 页面 MUST 提供可选择/复制的诊断摘要（含错误类别或短码、统一轨 seen/ok，且不含 token 明文）

### Requirement: Client SHALL record per-attributes Push-to-Start event seen separately from register success

For the unified Live Activity attributes type, the iOS client MUST track whether a `tokenKind=push_to_start` event was observed in-process (or since last explicit reset of the retry attempt) separately from whether `POST /app/api/push/live-activity/register` succeeded. The client MUST NOT require separate seen/ok flags for legacy `imminent` and `timing` attributes kinds.

对统一 Attributes，客户端 MUST 分别记录「是否见过 push_to_start 事件」与「是否 register 成功」；MUST NOT 再强制维护双 attributesKind 分轨 seen/ok。

#### Scenario: Token arrived but register failed

- **WHEN** 统一轨已收到 push_to_start 事件但 register 失败
- **THEN** 「已见事件」MUST 为真且「register 成功」MUST 为假
- **AND** 锁屏通知显态 MUST 能反映该分离状态

### Requirement: Lock-screen diagnosis SHALL distinguish native-delivered tokens that Dart did not observe

When a manual retry times out, if the native Push-to-Start deliver count is greater than zero and Dart recorded no `push_to_start` event for the unified attributes type in that attempt, the client MUST classify the failure as a dedicated category (code `native_deliver_dart_miss` or equivalent) and MUST NOT present it as a legacy dual-kind partial success. Native deliver count MUST increment only after a successful native-to-Dart `invokeMethod` of the token event, not when the channel object is nil.

手动重试超时且原生 PTS deliver 计数 > 0、本轮 Dart 未见统一轨事件时，客户端 MUST 使用独立错误类别 `native_deliver_dart_miss`（或等价），MUST NOT 展示为旧双轨「仅部分类型开通成功」。原生 deliver 计数 MUST 仅在成功 invoke 到 Dart 后增加。

#### Scenario: Native counted delivers but Dart saw none

- **WHEN** 用户手动重试超时
- **AND** 原生 `pushToStartDeliverCount` > 0
- **AND** 本轮统一轨 `ptsEventSeen` 为假
- **THEN** 锁屏通知页 MUST 展示表明「原生已投递、应用未收到」的失败信息与错误短码 `native_deliver_dart_miss`（或等价）
- **AND** MUST NOT 使用旧双轨「仅部分类型开通成功」类文案
