## ADDED Requirements

### Requirement: Clock-mode low-TOD copy SHALL share one title line with estimated-clock caption

When a hot non-appointment smart prediction card shows the countdown block in **estimated-clock mode**（`nextAt` overdue, or remaining duration strictly greater than six hours）and the prediction is marked time-of-day low-confidence, the client MUST render a single title line whose visible text is「此刻把握不足 · 预计{eventName}时刻」（middle dot with surrounding spaces as「 · 」), and MUST NOT place「此刻把握不足」on a separate row above that title. When the same card is in **live countdown mode**（not overdue and remaining ≤ six hours）and still low-confidence, the client MUST keep「此刻把握不足」on its own row above the title「距离下次{eventName}倒计时」and MUST NOT merge them with「 · 」. When the prediction is not low-confidence, title lines MUST remain unchanged（「预计{eventName}时刻」or「距离下次{eventName}倒计时」with no soft prefix）. Amount expect secondary copy（「预计约…」）MAY still appear on its own row; when present with the merged clock title, both MUST remain visible. Appointment roots MUST NOT show the soft copy.

热态非预约卡处于**预估时刻态**（逾期或剩余 &gt; 6 小时）且钟点把握不足时，标题 MUST 为单行「此刻把握不足 · 预计{事件名}时刻」，MUST NOT 再把「此刻把握不足」单独成行。处于**实时倒计时态**（未逾期且剩余 ≤ 6 小时）且把握不足时，MUST 仍将「此刻把握不足」独占一行置于「距离下次{事件名}倒计时」之上，MUST NOT 用「 · 」合并。未标记把握不足时标题 MUST 保持原样。用量 expect「预计约…」MAY 单独成行并与合并标题并存。预约根 MUST NOT 展示该软标。

#### Scenario: 时刻态软标与预计时刻同行

- **WHEN** 非预约热态卡为预估时刻态，且预测标记钟点把握不足
- **THEN** 倒计时区块标题行 MUST 包含「此刻把握不足 · 预计」与事件名及「时刻」
- **AND** MUST NOT 在该标题行上方再单独占一行「此刻把握不足」

#### Scenario: 倒计时态软标仍独占一行

- **WHEN** 非预约热态卡为实时倒计时态（未逾期且剩余 ≤ 6 小时），且预测标记钟点把握不足
- **THEN** MUST 单独展示「此刻把握不足」一行
- **AND** 其下标题 MUST 为「距离下次{事件名}倒计时」
- **AND** MUST NOT 出现「此刻把握不足 · 距离下次」形式的合并标题

#### Scenario: 热区时刻态无软标前缀

- **WHEN** 非预约热态卡为预估时刻态，且预测未标记钟点把握不足
- **THEN** 标题 MUST 为「预计{事件名}时刻」
- **AND** MUST NOT 含「此刻把握不足」
