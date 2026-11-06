## ADDED Requirements

### Requirement: Far upcoming countdown SHALL show estimated clock only when remaining exceeds six hours

When a hot (non-demo) smart prediction card shows the next-occurrence countdown block and `nextAt` is still in the future, if the remaining duration until `nextAt` is **strictly greater than six hours**, the large time area MUST display only the estimated local clock for `nextAt` (same day-boundary formatting as the overdue estimated-clock path: today `HH:mm` without 「今天」; yesterday with a 「昨天」prefix; earlier days with a month-day prefix plus `HH:mm`), and MUST NOT display the live `H:MM:SS` countdown. When remaining duration is less than or equal to six hours and not overdue, the large time area MUST remain the live `H:MM:SS` countdown. When the card is in estimated-clock display mode for this far-upcoming reason OR because `nextAt` is overdue, the countdown block title MUST be 「预计{eventName}时刻」; when showing the live countdown (not overdue and remaining ≤ six hours), the title MUST remain 「距离下次{eventName}倒计时」. Appointment and non-appointment cards that share the countdown block MUST follow the same rules.

热态非骨架预测卡在展示下次倒计时区块且 `nextAt` 仍在未来时，若距 `nextAt` 的剩余时长**严格大于 6 小时**，大数字区 MUST **只**展示预估本地时刻（日界与逾期预估时刻一致：今天仅 `HH:mm` 且无「今天」；昨天带「昨天」前缀；更早为月日 + `HH:mm`），MUST NOT 展示实时 `H:MM:SS` 倒计时。剩余时长 ≤ 6 小时且未逾期时，大数字 MUST 仍为实时 `H:MM:SS`。因远距或因逾期而处于预估时刻展示态时，标题 MUST 为「预计{事件名}时刻」；展示实时倒计时（未逾期且剩余 ≤ 6 小时）时标题 MUST 仍为「距离下次{事件名}倒计时」。共用该倒计时区块的预约与非预约卡 MUST 一致。

#### Scenario: 剩余大于 6 小时只显示时刻

- **WHEN** 热态卡有倒计时区块，`nextAt` 在未来，且剩余时长 &gt; 6 小时
- **THEN** 大数字区 MUST 为预估本地时刻（非 `H:MM:SS`）
- **AND** 标题 MUST 为「预计{事件名}时刻」

#### Scenario: 剩余不超过 6 小时保持倒计时

- **WHEN** 热态卡有倒计时区块，`nextAt` 在未来，且剩余时长 ≤ 6 小时
- **THEN** 大数字区 MUST 为向 `nextAt` 的 `H:MM:SS` 倒计时
- **AND** 标题 MUST 为「距离下次{事件名}倒计时」

#### Scenario: 恰好 6 小时仍倒计时

- **WHEN** 剩余时长恰好等于 6 小时且未逾期
- **THEN** 大数字区 MUST 仍为倒计时（因阈值为严格大于 6 小时）

### Requirement: Estimated clock date prefix SHALL use a smaller type size than HH:mm

When the prediction card large time area displays an estimated `nextAt` clock string that includes a date prefix（「昨天」or a month-day label）, that date prefix MUST be rendered at a noticeably smaller font size than the `HH:mm` digits. When the clock falls on the local today and has no date prefix, the `HH:mm` digits MAY use the existing large countdown type size alone. This applies both to overdue estimated-clock mode and to far-upcoming estimated-clock mode（remaining &gt; six hours）.

当预测卡大数字区展示含日期前缀（「昨天」或月日）的预估 `nextAt` 时刻时，该日期前缀字号 MUST 明显小于 `HH:mm`。落在本地今天、无日期前缀时，`HH:mm` MAY 单独使用既有大号倒计时字号。本条适用于逾期预估时刻态与远距（剩余 &gt; 6 小时）预估时刻态。

#### Scenario: 跨日时刻日期更小

- **WHEN** 大数字区展示带「昨天」或月日的预估时刻
- **THEN** 日期前缀字号 MUST 小于 `HH:mm` 字号

#### Scenario: 今日时刻无日期前缀

- **WHEN** 大数字区展示落在本地今天的预估时刻
- **THEN** MUST NOT 出现「今天」前缀
- **AND** 大数字可为单独的 `HH:mm`
