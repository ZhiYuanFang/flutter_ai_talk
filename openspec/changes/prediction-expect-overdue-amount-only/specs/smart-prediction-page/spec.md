## MODIFIED Requirements

### Requirement: Prediction cards SHALL show winning expect as secondary copy

When a hot prediction card has a non-null `nextAt` prediction, the client MAY compute a winning expect per `event-expect-prediction`, but card secondary「预计约…」copy MUST follow these display gates:

- **Duration expect** (`expectKind` duration / 下次用时): the client MUST NOT render the card secondary expect line for duration, even when a winning duration expect exists.
- **Amount expect** (`expectKind` amount / 下次用量): the client MUST render the secondary「预计约…」amount line only when the card countdown is in the **overdue** state (`isOverdue` or equivalent). While the countdown is not overdue, the client MUST NOT show amount expect copy.
- When no expect line is shown, the client MUST NOT reserve an empty placeholder.
- Active-timing compact cards' estimated-end line (`activeEtaLabel` / 「预计还要多久结束」) MUST NOT be changed by this requirement; it remains independent of the next-expect gates above.
- When the card also renders a countdown block and an amount expect line is shown (overdue only), that line MUST remain immediately above the countdown text (below any hero logo above that countdown). Landscape compact layout MAY omit the leaf title while keeping quantity/unit.

热态卡次级「预计约…」：**用时（duration）MUST NOT 展示**；**用量（amount）仅倒计时已超时才展示**；无文案 MUST NOT 空白占位；计时中预计结束行 MUST NOT 因本条改动；超时展示用量时仍紧贴倒计时上方；横屏 MAY 省略叶子名。

#### Scenario: Duration expect hidden on card

- **WHEN** 热态卡存在 `nextAt` 且胜出 expect 为 duration（无论是否超时）
- **THEN** 卡片 MUST NOT 展示「预计约…」用时次级文案

#### Scenario: Amount expect hidden before overdue

- **WHEN** 热态卡存在 `nextAt`、胜出 expect 为 amount，且倒计时未超时
- **THEN** 卡片 MUST NOT 展示「预计约…」用量次级文案

#### Scenario: Amount expect shown when overdue

- **WHEN** 热态卡存在 `nextAt`、胜出 expect 为 amount，且倒计时已超时
- **THEN** 卡片 MUST 展示「预计约…」用量文案（含数量与单位；竖屏 MAY 含叶子名）
- **AND** 该文案 MUST 位于倒计时正上方（有大 logo 时在 logo 与倒计时之间）

#### Scenario: Active timing ETA unchanged

- **WHEN** 紧凑卡处于计时中且有 duration 把握的预计结束文案
- **THEN** 客户端 MUST 仍按既有规则展示计时中预计结束行
- **AND** MUST NOT 因本变更的 duration/amount 门闩隐藏或改写该行

#### Scenario: No expect — no placeholder

- **WHEN** 热态卡有 `nextAt` 但不满足上述用量超时展示条件（含无胜出 amount、或仅有 duration）
- **THEN** 卡片 MUST NOT 展示空的预计用量/用时行
