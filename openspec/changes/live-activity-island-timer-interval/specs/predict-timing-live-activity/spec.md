## ADDED Requirements

### Requirement: Timing Dynamic Island elapsed SHALL use system timerInterval

When the system presents a Timing Live Activity on the Dynamic Island (compact trailing and expanded trailing), the elapsed time SHALL be rendered with SwiftUI `Text(timerInterval:)` (or an equivalent ActivityKit system-driven timer Text) from `startTime` (unix seconds), with `countsDown: false`. The timer interval MUST use a finite upper bound (approximately 99 hours from `startTime`) and MUST NOT use `Date.distantFuture`. The client MUST NOT rely on `TimelineView` plus a manually formatted `hh:mm:ss` string as the primary Island elapsed display. Compact trailing MUST continue to report a short intrinsic width via `CompactIslandTimeSlot` (or equivalent hidden `"00:00:00"` placeholder) so the live timer MUST NOT set the island width by unbounded measurement.

当系统在 Dynamic Island 展示 Timing Live Activity 时（compact trailing 与 expanded trailing），已计时 MUST 使用 SwiftUI `Text(timerInterval:)`（或等价系统驱动计时 Text），自 `startTime`（unix 秒）起、`countsDown: false`。区间 MUST 有有限上界（约自 `startTime` 起 99 小时），MUST NOT 使用 `Date.distantFuture`。MUST NOT 再以 `TimelineView` + 手写 `hh:mm:ss` 作为 Island 主已计时展示。compact trailing MUST 仍经 `CompactIslandTimeSlot`（或等价隐藏 `"00:00:00"` 占位）报告短固有宽度，系统 timer MUST NOT 以无界测量决定岛宽。

#### Scenario: Compact island timer ticks without stretching

- **WHEN** 系统以 compact Dynamic Island 展示一条 Timing Live Activity 且 `startTime` 为有效 unix 秒
- **THEN** compact trailing MUST 以系统 `timerInterval`（或等价）展示自 `startTime` 起的已计时并随时间前进
- **AND** compact 岛 MUST 保持胶囊宽度，MUST NOT 被拉到接近满屏宽

#### Scenario: Expanded island trailing ticks

- **WHEN** 用户展开该 Timing Live Activity 的 Dynamic Island
- **THEN** expanded trailing MUST 以系统 `timerInterval`（或等价）展示自 `startTime` 起的已计时并随时间前进

#### Scenario: No TimelineView primary path

- **WHEN** Timing Live Activity 在 Dynamic Island 展示已计时
- **THEN** 主路径 MUST NOT 仅为 `TimelineView` 周期自算并格式化为固定 `hh:mm:ss` 字符串
