## MODIFIED Requirements

### Requirement: Empty accuracy chart SHALL show labeled sample bars on every such card

When the smart prediction **vertical list** (non-compact) card chart region has **no** eligible accuracy samples for that event root in the near-window (i.e. every day percent would be null under the existing scoring rules), the client MUST choose between sample demonstration and empty placeholder using a **page-level real-sample gate**:

- If **no** vertical-list accuracy card on the current list has any eligible real sample in its near-window, then every such empty card MUST render a **sample** near-N-day accuracy bar chart (MUST NOT only show「暂无预测对照」as the sole prior behavior without sample teaching). Sample day percents MUST intentionally vary high and low. The client MUST show a short centered caption / title segment stating sample/example data (e.g.「预测准确率分布图 · 示例数据」). Sample chart MUST NOT show next-occurrence or last-occurrence copy inside the chart region.
- If **at least one** vertical-list accuracy card on the current list has ≥1 eligible real sample in its near-window, then every **other** card that still has zero eligible samples MUST render an **empty placeholder** in the chart region (centered「暂无预测对照」or equivalent). Those cards MUST NOT show sample bars, MUST NOT offer sample day summary, and MUST NOT mix sample bars with real bars.

When a given card itself has at least one day with a real eligible sample, the client MUST show only the real accuracy chart for that card and MUST NOT mix sample bars with real bars. Sample data MUST NOT be written to history, accuracy aggregates, or push pending.

当预测竖列表对照卡近窗对该根**无**合格准确率样本时：若**当前列表没有任何**对照卡有真样本，则零样本卡 MUST 仍出示例柱（冷启动教学）；若**至少一张**对照卡已有真样本，则其余零样本卡 MUST 改空态占位「暂无预测对照」，MUST NOT 再出示例柱/示例小结。本卡有真样本时 MUST 只出真柱。示例 MUST NOT 写入 history / 汇总 / pending。

#### Scenario: All cards empty still show sample

- **WHEN** every vertical-list accuracy card’s near-window has zero eligible real samples
- **THEN** each such empty card’s chart region shows the sample accuracy UI with sample/example labeling

#### Scenario: One real card gates others to empty placeholder

- **WHEN** at least one vertical-list accuracy card has ≥1 eligible real sample
- **AND** another card on the same list has zero eligible samples
- **THEN** the zero-sample card’s chart region shows empty placeholder copy（如「暂无预测对照」）
- **AND** MUST NOT show sample accuracy bars or sample day summary

#### Scenario: Real samples replace sample UI on that card

- **WHEN** a card later has at least one eligible accuracy sample in the window
- **THEN** that card’s chart region shows only the real accuracy bars
- **AND** MUST NOT continue showing sample bars alongside real bars

## ADDED Requirements

### Requirement: Accuracy empty placeholder MUST NOT be interactive sample chrome

When a vertical-list accuracy chart region is in the gated empty-placeholder state (page has real samples elsewhere; this card has none), taps on that chart region MUST NOT open a sample day summary and MUST NOT navigate away. The region MAY absorb taps so they do not trigger the card add-event path, consistent with bars-mode empty chrome absorption.

页级门闩下的空态占位 MUST NOT 进入示例小结；图区点击 MUST NOT 触发加事件（可吸收）。

#### Scenario: Tap empty placeholder stays on card

- **WHEN** the user taps the gated empty accuracy placeholder
- **THEN** the client MUST NOT show sample summary bars-to-summary transition
- **AND** MUST NOT treat the tap as the card’s primary add-event action
