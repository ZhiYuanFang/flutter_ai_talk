## ADDED Requirements

### Requirement: Chat WS MUST honor hold uplink protection against server mic-stop frames

The `/voice/chat/ws` client MUST support an explicit hold-uplink protection latch (name implementation-defined) that portrait PTT sets while the finger hold is active. When that latch is enabled, handling of server `interrupt_commit` and `asr_no_result` MUST still notify listeners as today where applicable, but MUST NOT call mic-stop (`_stopMicOnly` or equivalent). When the latch is disabled (landscape dialogue and after portrait release/teardown), existing behavior MUST remain: `interrupt_commit` and `asr_no_result` MAY stop the mic as they do today. `/voice/chat/ws` 客户端 MUST 提供 hold 上行保护门闩；门闩开启时 `interrupt_commit` / `asr_no_result` MUST NOT 停麦；门闩关闭时横屏既有停麦行为 MUST 保持。

#### Scenario: Protected interrupt_commit keeps recording

- **WHEN** hold 上行保护门闩为开启
- **AND** 收到 `interrupt_commit`
- **THEN** 客户端 MUST NOT 停止麦克风采集
- **AND** MUST 仍向编排层投递 interrupt 事件（供忽略业务收口）

#### Scenario: Protected asr_no_result keeps recording

- **WHEN** hold 上行保护门闩为开启
- **AND** 收到 `asr_no_result`
- **THEN** 客户端 MUST NOT 停止麦克风采集
- **AND** MUST 仍向编排层投递对应结束/空结果事件（编排层按住期间 MUST NOT 误导性改写为已失败收口 UI）

#### Scenario: Landscape unprotected path unchanged

- **WHEN** hold 上行保护门闩为关闭（横屏对话）
- **AND** 收到 `interrupt_commit`
- **THEN** 客户端 MUST 按既有横屏行为停止麦克风（或等价停麦）
