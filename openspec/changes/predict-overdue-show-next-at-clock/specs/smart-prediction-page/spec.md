## ADDED Requirements

### Requirement: Overdue prediction countdown SHALL show estimated nextAt clock time

When a hot (non-demo) smart prediction card shows the next-occurrence countdown block and the prediction’s `nextAt` is overdue relative to now, the large time digits MUST display the estimated `nextAt` as a local clock string, and MUST NOT display the frozen `00:00:00` stopwatch. When `nextAt` falls on the same local calendar day as now, the digits MUST be `HH:mm` and MUST NOT include a 「今天」 prefix. When `nextAt` is on the previous local calendar day, the digits MUST use a 「昨天 HH:mm」 form. When `nextAt` is on an earlier local day, the digits MUST include a month-day label with `HH:mm` (same day-boundary spirit as the card’s last-occurrence clock formatting). While not overdue, the digits MUST remain a live countdown `H:MM:SS` (hours may exceed 24). In the overdue state, the countdown block title MUST be 「预计{eventName}时刻」 (using the same event display name as the non-overdue title). While not overdue, the title MUST remain 「距离下次{eventName}倒计时」。This requirement applies to appointment and non-appointment cards that share that countdown block. Secondary relative copy such as 「已超时」MAY remain unchanged.

热态非骨架预测卡在展示下次倒计时区块且 `nextAt` 相对现在已逾期时，大数字 MUST 展示预估 `nextAt` 的本地钟点串，MUST NOT 再固定为停表 `00:00:00`。`nextAt` 与现在同本地自然日时 MUST 为 `HH:mm` 且 MUST NOT 含「今天」；为昨日本地日时 MUST 为「昨天 HH:mm」；更早 MUST 含月日 + `HH:mm`（日界精神与卡上「上一次」钟点一致）。未逾期时大数字 MUST 仍为实时倒计时 `H:MM:SS`（小时可超过 24）。逾期时倒计时区标题 MUST 为「预计{事件名}时刻」（事件名与未逾期标题同源）；未逾期 MUST 仍为「距离下次{事件名}倒计时」。共用该倒计时区块的预约与非预约卡 MUST 一致。旁侧「已超时」等相对文案 MAY 保持不变。

#### Scenario: 今日逾期显示 HH:mm 且无「今天」

- **WHEN** 热态卡有倒计时区块，且 `nextAt` 已逾期并落在本地今天
- **THEN** 大数字 MUST 为 `HH:mm`（由 `nextAt` 本地时分得出）
- **AND** MUST NOT 包含「今天」
- **AND** MUST NOT 为 `00:00:00`

#### Scenario: 昨日逾期显示昨天前缀

- **WHEN** 热态卡有倒计时区块，且 `nextAt` 已逾期并落在本地昨天
- **THEN** 大数字 MUST 匹配「昨天 HH:mm」语义

#### Scenario: 逾期标题切换

- **WHEN** 热态卡倒计时区块处于逾期态
- **THEN** 标题 MUST 为「预计{事件名}时刻」
- **AND** MUST NOT 仍为「距离下次{事件名}倒计时」

#### Scenario: 未逾期保持倒计时与原标题

- **WHEN** 热态卡有倒计时区块且 `nextAt` 仍在未来
- **THEN** 大数字 MUST 为向 `nextAt` 的 `H:MM:SS` 倒计时
- **AND** 标题 MUST 为「距离下次{事件名}倒计时」
