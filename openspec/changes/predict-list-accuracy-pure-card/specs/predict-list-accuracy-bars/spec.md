## ADDED Requirements

### Requirement: Vertical list accuracy card chrome SHALL be accuracy-only

On the smart prediction **vertical list** (non-compact) card that shows the accuracy chart region, the client MUST show only the event logo, event name, forecast enable Switch, and the accuracy chart/summary region. The client MUST hide next-occurrence countdown / appointment countdown blocks, relative-time copy, last-occurrence row, expect secondary copy such as「预计约…」, supplement CTAs (补上一次 / 补充下次 / 补充大概多久一次), and the in-progress timing block (elapsed, expect-end line, and Stop). When that event root is actively timing, the vertical-list card MUST still omit the Stop control and other timing chrome and MUST continue to show only the accuracy chart region (plus title row). Horizontal / waterfall / compact card layouts are out of scope for this requirement.

预测竖列表（非 compact）且展示准确率图区的卡，客户端 MUST 仅展示事件 logo、事件名、推演 Switch 与准确率图区/小结。MUST 隐藏下次倒计时/预约倒计时、relative 文案、上一次行、「预计约…」类次级文案、补充 CTA，以及计时中整块（已用时、预计结束、停止）。该根正在计时时，竖列表卡 MUST 仍不展示停止条及其它计时 chrome，MUST 继续只展示准确率图区（外加标题行）。横滑/瀑布/compact 不在本需求范围。

#### Scenario: Hot card shows title and chart only

- **WHEN** a vertical-list prediction card has a prediction and renders the accuracy chart
- **THEN** the card shows logo, name, forecast Switch, and the accuracy chart region
- **AND** it does not show countdown, last-occurrence, relative-time, expect-about copy, or supplement CTAs

#### Scenario: Active timing still has no Stop on vertical accuracy card

- **WHEN** the same event root is actively timing and the vertical-list accuracy card is visible
- **THEN** the card does not show the Stop control or timing elapsed block
- **AND** the accuracy chart region remains available

### Requirement: Accuracy chart title SHALL name the distribution and mark samples

The accuracy bar chart region MUST show a centered title「预测准确率分布图」whose text color follows the card event accent. When the chart is in sample/empty demonstration mode, the title MUST be「预测准确率分布图 · 示例数据」with both segments using the event accent (MUST NOT rely solely on a separate muted「示例数据」caption as the only label). The title MUST NOT include next-occurrence or last-occurrence copy.

准确率柱图区 MUST 居中标题「预测准确率分布图」，文案色跟随事件 accent。示例空态标题 MUST 为「预测准确率分布图 · 示例数据」，两段均随 accent；MUST NOT 仅靠单独 muted「示例数据」作为唯一标识。标题 MUST NOT 含下次/上一次文案。

#### Scenario: Real chart title

- **WHEN** the accuracy bars show real samples
- **THEN** the centered title is「预测准确率分布图」in the event accent color

#### Scenario: Sample chart title

- **WHEN** the accuracy bars are sample/empty demonstration data
- **THEN** the centered title is「预测准确率分布图 · 示例数据」in the event accent color

### Requirement: Day summary back control SHALL be a leading arrow

When the in-card day summary is visible, the client MUST provide a leading back control that returns to the near-N-day accuracy bars. That control MUST be an arrow/chevron affordance and MUST NOT use the copy「近7日」as the primary back label.

卡内日小结可见时，客户端 MUST 提供返回近 N 日准确率柱的控件；该控件 MUST 为箭头/chevron，MUST NOT 以「近7日」文案作为主返回标签。

#### Scenario: Back from summary

- **WHEN** the user activates the leading back control on the day summary
- **THEN** the chart region returns to the accuracy bars
- **AND** the back control is not labeled「近7日」

### Requirement: Accuracy detail row SHALL combine time and optional quantity with traffic color

Each eligible occurrence row in the day summary MUST render a single line of the form「预计 HH:mm[ · quantity] → 实际 HH:mm[ · quantity]」and MUST NOT show「准」/「偏」labels. The quantity segment MUST use amount+unit when amount expect/actual are available; otherwise when a duration expect/actual is available the quantity segment MUST use duration copy. For one-shot events (`eventType=one`) or when no quantity/duration dimension is available, the client MUST omit the quantity segments entirely. The whole line text color MUST follow a traffic tier from the composite alignment score: green when score ≥ 70, yellow when score ≥ 40 and &lt; 70, red when score &lt; 40. Sample summary rows MUST follow the same shape and coloring rules and MUST NOT write history.

日小结每条合格发生 MUST 单行展示「预计 HH:mm[ · 量] → 实际 HH:mm[ · 量]」，MUST NOT 展示「准/偏」。量段：有用量期望/实际则用量+单位；否则有时长期望/实际则时长文案。一次性（`eventType=one`）或无任何量/时长维时 MUST 省略量段。整行色 MUST 按合成分：≥70 绿、≥40 且 &lt;70 黄、&lt;40 红。示例小结 MUST 同形态同着色，MUST NOT 写 history。

#### Scenario: Amount event detail line

- **WHEN** a summary row has start expect/actual and amount expect/actual
- **THEN** the line includes both times and amount segments in the预计/实际 form
- **AND** the line color matches the composite score tier
- **AND** no「准」or「偏」label is shown

#### Scenario: One-shot omits quantity

- **WHEN** the event is one-shot (`eventType=one`) or has no quantity/duration dimension
- **THEN** the detail line shows only预计/实际 times without ` · ` quantity segments

#### Scenario: Duration fills quantity slot

- **WHEN** amount expect is absent but duration expect and actual duration are available
- **THEN** the quantity segments use duration copy rather than amount

### Requirement: Daily accuracy percent SHALL use weighted time and quantity alignment

For each eligible history occurrence under the card’s event root, the client MUST compute a time alignment score `S_time` in 0–100 from `|actualStart − expectStart|` (full score when difference ≤ 1800 seconds, zero when difference ≥ 7200 seconds, linear between). When a quantity or duration dimension is present, the client MUST compute `S_qty` in 0–100 from relative error `|actual − expect| / max(|expect|, ε)` (full score at 0 error, zero at relative error ≥ 0.5, linear between). The composite score MUST be `0.7 * S_time + 0.3 * S_qty` when both dimensions are present, and MUST be `S_time` alone when quantity/duration is absent (including one-shot). The day’s accuracy percent on the bar chart MUST be the rounded mean of that day’s composite scores. The client MUST NOT score by replaying the predictor to invent missing expect fields. Sample day percents used in empty demonstration MUST remain deliberately varied but MUST NOT be mixed into real aggregates.

对卡事件根下每条合格历史发生，客户端 MUST 由 `|实际开始 − 预计开始|` 得到 0–100 的 `S_time`（≤1800 秒满分，≥7200 秒零分，中间线性）。存在用量或时长维时 MUST 由相对误差得到 `S_qty`（0 误差满分，相对误差≥0.5 零分，中间线性）。两维都有时合成分 MUST 为 `0.7*S_time+0.3*S_qty`；缺量（含一次性）MUST 仅为 `S_time`。柱图日准确率 % MUST 为该日合成分均值四舍五入。MUST NOT 重放预报伪造缺失 expect。示例假 % 可故意起伏，MUST NOT 混入真聚合。

#### Scenario: Time-only day percent

- **WHEN** a day has eligible rows with start expect only (no quantity/duration)
- **THEN** each row’s composite equals its `S_time`
- **AND** the day’s bar percent is the rounded mean of those scores

#### Scenario: Weighted row with amount

- **WHEN** a row has both start and amount dimensions
- **THEN** its composite is `0.7 * S_time + 0.3 * S_qty`
- **AND** that composite contributes to the day’s mean percent and to the row’s traffic color
