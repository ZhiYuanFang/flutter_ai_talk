## ADDED Requirements

### Requirement: Empty accuracy chart SHALL show labeled sample bars on every such card

When the smart prediction **vertical list** (non-compact) card chart region has **no** eligible accuracy samples for that event root in the near-window (i.e. every day percent would be null under the existing scoring rules), the client MUST render a **sample** near-N-day accuracy bar chart instead of only the copy「暂无预测对照». Every vertical-list card in that empty state MUST show the sample chart (not a one-shot global tutorial). Sample day percents MUST intentionally vary high and low across days so the chart is glanceable as an accuracy comparison. The client MUST show a short centered caption above the sample bars stating that the content is sample/example data. The sample chart region MUST NOT display next-occurrence countdown copy or last-occurrence time copy. Card chrome outside the chart region (including countdown and「上一次」when already shown by the card) MUST remain governed by existing prediction-card rules and is out of scope for removal by this requirement. When at least one day has a real eligible sample, the client MUST show only the real accuracy chart and MUST NOT mix sample bars with real bars. Sample data MUST NOT be written to history, accuracy aggregates, or push pending.

当预测竖列表（非 compact）卡图区在近窗内对该事件根**没有任何**合格准确率样本时，客户端 MUST 渲染**示例**近 N 日准确率柱，MUST NOT 仅显示「暂无预测对照」。每一张处于该空态的竖卡 MUST 都展示示例（非全局只教一次）。示例日准确率 MUST 故意有高有低以便一眼可读。柱上方 MUST 居中短文案标明示例/示例数据。示例图区 MUST NOT 展示下次预测倒计时或上一次发生时间文案。卡图区外的倒计时与「上一次」仍按既有预测卡规则，本需求 MUST NOT 要求隐藏它们。只要有一日存在真合格样本，MUST 只展示真对照柱，MUST NOT 真假混柱。示例 MUST NOT 写入 history、准确率汇总或推送 pending。

#### Scenario: Card with no samples shows sample bars and caption

- **WHEN** a vertical-list prediction card’s accuracy window has zero eligible samples for its event root
- **THEN** the chart region shows sample accuracy bars with deliberately varied percents
- **AND** a centered small caption above the bars indicates sample/example data
- **AND** the chart region does not show next-prediction or last-occurrence time copy

#### Scenario: Every empty card shows sample

- **WHEN** multiple vertical-list cards each have zero eligible accuracy samples
- **THEN** each such card’s chart region shows the sample accuracy UI

#### Scenario: Real samples replace sample UI

- **WHEN** the same card later has at least one eligible accuracy sample in the window
- **THEN** the chart region shows only the real accuracy bars
- **AND** MUST NOT continue showing sample bars alongside real bars

### Requirement: Sample accuracy bars SHALL support in-card sample day summary

When the user taps a sample day bar, the client MUST replace the same card’s chart region with a **sample** day summary listing one or more「预计 HH:mm → 实际 HH:mm」rows (with hit/miss styling consistent with real summary), MUST keep an explicit sample/example indication on that summary, and MUST provide a control to return to the sample bars (e.g.「近7日」). The summary MUST NOT navigate to another route as the primary presentation. The sample summary MUST NOT include next-occurrence or last-occurrence fields. Taps in the chart region MUST NOT trigger the card’s add-event / whole-card tap action.

用户点示例日柱时，客户端 MUST 在同卡图区替换为示例当日小结（预计→实际行，准/偏样式与真小结一致），MUST 保留示例标识，MUST 提供返回示例柱图的控件。MUST NOT 以跳转他页为主呈现。示例小结 MUST NOT 含下次/上一次字段。图区点击 MUST NOT 触发整卡加事件。

#### Scenario: Tap sample bar opens sample summary

- **WHEN** the user taps a sample day bar on an empty-state card
- **THEN** the chart region shows a sample predict-vs-actual summary for that day
- **AND** sample/example labeling remains visible
- **AND** a control returns to the sample bars

#### Scenario: Sample summary has no next/last fields

- **WHEN** the sample day summary is visible
- **THEN** it does not show next-prediction countdown or last-occurrence time rows
