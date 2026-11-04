## MODIFIED Requirements

### Requirement: Lock-screen status UI SHALL expose diagnosable registration stages

The lock-screen settings page MUST make it possible, without system logs, to distinguish at least: unsupported OS version for Push-to-Start, system Live Activities disallowed, listening not started / waiting for system token, per-`attributesKind` (`imminent` and `timing`) whether a Push-to-Start **event was received** versus whether `live-activity/register` **succeeded**, HTTP/register failures, partial success (only one attributes kind), and timeout-while-keeping-prior-success. The page MUST show a human-readable failure summary and MUST also expose a compact copyable diagnostic summary (OS major version, listening flag, optional native push-to-start deliver count, per-kind seen/ok flags, error category code). The client MUST NOT display the raw push token. When a retry ends in timeout, if an HTTP/register error was already recorded for that attempt, the client MUST NOT overwrite it with a generic 「waiting for system token」 message. 「已开通」MUST require both `imminent` and `timing` Push-to-Start registrations to have succeeded under the client's recorded success criteria.

锁屏通知页 MUST 在无系统日志时可区分上述阶段（含「收到 PTS 事件」与「register 成功」分离、部分成功、HTTP 失败、保留上次成功的超时）；MUST 提供人话失败摘要与可复制诊断摘要；MUST NOT 展示原始 token；本轮已有 HTTP 错误时 MUST NOT 被笼统「等系统 token」覆盖。「已开通」MUST 要求两类 Push-to-Start 均已成功上报。

#### Scenario: Both attributes registered

- **WHEN** 客户端已成功为 `imminent` 与 `timing` 完成 `tokenKind=push_to_start` 的 `live-activity/register`
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

#### Scenario: Partial attributes success visible

- **WHEN** 手动重试结束时仅 `imminent` 或仅 `timing` 的 Push-to-Start 注册成功
- **THEN** 页面 MUST 分 attributes 展示成败
- **AND** 下方 MUST 表明部分开通/未完成，而非仅笼统「已开通」或仅笼统超时

#### Scenario: Copyable diagnostic summary

- **WHEN** 用户打开锁屏通知页或完成一次手动重试
- **THEN** 页面 MUST 提供可选择/复制的诊断摘要（含错误类别或短码、分 kind 的 seen/ok，且不含 token 明文）

## ADDED Requirements

### Requirement: Client SHALL record per-attributes Push-to-Start event seen separately from register success

For each of `imminent` and `timing`, the iOS client MUST track whether a `tokenKind=push_to_start` event was observed in-process (or since last explicit reset of the retry attempt) separately from whether `POST /app/api/push/live-activity/register` succeeded for that kind. 对 imminent 与 timing，客户端 MUST 分别记录「本进程/本轮是否见过 push_to_start 事件」与「是否 register 成功」。

#### Scenario: Token arrived but register failed

- **WHEN** 某 attributesKind 已收到 push_to_start 事件但 register 失败
- **THEN** 该 kind 的「已见事件」MUST 为真且「register 成功」MUST 为假
- **AND** 锁屏通知显态 MUST 能反映该分离状态
