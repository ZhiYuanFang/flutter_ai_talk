## ADDED Requirements

### Requirement: Timing lock screen SHALL show optional expect-end subtitle under the event name

When the system presents a Timing Live Activity on the lock screen and ContentState (or an agreed ContentState field readable by the widget) provides a positive `expectEndAt` unix-seconds value, the client MUST show a secondary line directly under the event-name title with short copy of the form「预计 HH:mm 结束」, where `HH:mm` is the local-calendar hour and minute of `expectEndAt`. The client MUST NOT append「约」or an overdue suffix such as「· 已超时」on this subtitle. When `expectEndAt` is missing, zero, or otherwise unusable, the client MUST omit the subtitle and MUST NOT reserve empty vertical space for it. The trailing system-driven elapsed timer from `startTime` MUST remain on the right of the bottom row and MUST NOT move under the title. Dynamic Island Timing presentation MUST NOT be required to show this subtitle. Decoding MUST tolerate older pushes that omit `expectEndAt`.

当系统展示 Timing Live Activity 锁屏且 ContentState 提供正的 `expectEndAt`（unix 秒）时，客户端 MUST 在事件名主标题正下方展示短文案「预计 HH:mm 结束」（`HH:mm` 为 `expectEndAt` 的本地日历时分）。MUST NOT 在该副行追加「约」或「· 已超时」等超时后缀。`expectEndAt` 缺失、为 0 或不可用时 MUST 省略副行，MUST NOT 为空副行预留竖直空隙。下层右侧自 `startTime` 起的系统已计时 MUST 保留，MUST NOT 挪到标题下方。MUST NOT 要求 Timing Dynamic Island 展示该副行。解码 MUST 容忍旧推送缺省 `expectEndAt`。

#### Scenario: Subtitle under event name when expectEndAt present

- **WHEN** Timing 锁屏 ContentState 含有效正 `expectEndAt`（例如对应本地 14:30）
- **THEN** 事件名下方 MUST 显示「预计 14:30 结束」（或等价零填充 HH:mm）
- **AND** MUST NOT 含「约」
- **AND** 右侧 MUST 仍展示自 `startTime` 起的已计时

#### Scenario: No subtitle when expectEndAt absent

- **WHEN** Timing 锁屏推送未带 `expectEndAt`（或值为 0）
- **THEN** MUST NOT 在事件名下展示「预计 … 结束」
- **AND** 锁屏其余双层布局与已计时行为 MUST 保持可用

#### Scenario: Island unchanged for expect-end

- **WHEN** Timing 以 Dynamic Island 展示且 ContentState 含 `expectEndAt`
- **THEN** MUST NOT 要求 Island 增加「预计 HH:mm 结束」副行
