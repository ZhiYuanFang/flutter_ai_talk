## ADDED Requirements

### Requirement: Lock-screen diagnosis SHALL distinguish native-delivered tokens that Dart did not observe

When a manual retry times out, if the native Push-to-Start deliver count is greater than zero and Dart recorded no `push_to_start` event for either `imminent` or `timing` in that attempt, the client MUST classify the failure as a dedicated category (code `native_deliver_dart_miss` or equivalent) and MUST NOT present it as `partial_attributes`（仅部分类型开通成功）. Native deliver count MUST increment only after a successful native-to-Dart `invokeMethod` of the token event, not when the channel object is nil.

手动重试超时且原生 PTS deliver 计数 > 0、本轮 Dart 两类均未见事件时，客户端 MUST 使用独立错误类别 `native_deliver_dart_miss`（或等价），MUST NOT 展示为「仅部分类型开通成功」。原生 deliver 计数 MUST 仅在成功 invoke 到 Dart 后增加。

#### Scenario: Native counted delivers but Dart saw none

- **WHEN** 用户手动重试超时
- **AND** 原生 `pushToStartDeliverCount` > 0
- **AND** 本轮 `imminent` 与 `timing` 的 `ptsEventSeen` 均为假
- **THEN** 锁屏通知页 MUST 展示表明「原生已投递、应用未收到」的失败信息与错误短码 `native_deliver_dart_miss`（或等价）
- **AND** MUST NOT 使用「仅部分类型开通成功」类文案

#### Scenario: Partial attributes remains for one-kind success

- **WHEN** 手动重试结束时 Dart 至少见过一类 `push_to_start` 或至少一类 register 成功，但两类未齐
- **THEN** 客户端 MAY 继续使用 `partial_attributes`
- **AND** MUST 分 attributes 展示 seen/ok
