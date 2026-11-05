## ADDED Requirements

### Requirement: Prediction vertical list cards SHALL show a 7-day accuracy bar chart

The smart prediction **vertical list** (non-compact) card chart region MUST replace the lookback line chart with a near-7-calendar-day **accuracy** bar chart for that card’s event root. Bar height MUST encode that day’s accuracy percent (0–100). Days with at least one eligible sample MUST show an integer percent label above the bar. Days with no eligible sample MUST NOT draw a bar and MUST NOT show `0%`. Accuracy MUST use stored `expectStartTime` only: a sample is eligible iff `expectStartTime > 0` and actual start is present; a hit is `|actualStart − expectStartTime| ≤ 1800` seconds; day percent MUST be `round(100 * hits / samples)`. The client MUST NOT replay the predictor to fabricate expect values for unscored rows. Horizontal / waterfall / cast layouts are out of scope for this requirement. 预测竖列表大卡图区 MUST 以近 7 日准确率柱替换折线；柱高与柱顶 % 表示日准确率；无合格样本日 MUST NOT 画柱或标 0%；计分仅认已存 expectStartTime、30 分钟命中、禁止重放；横滑/瀑布/投屏不在本条范围。

#### Scenario: Day with samples shows bar and percent

- **WHEN** the vertical list card has history rows for a calendar day with eligible `expectStartTime` samples
- **THEN** that day shows a bar whose height matches the day’s accuracy percent and a top label with the rounded integer percent

#### Scenario: Day without samples stays empty

- **WHEN** a calendar day in the 7-day window has zero eligible samples
- **THEN** that day slot shows no bar and no percent label

#### Scenario: No replay of expect

- **WHEN** a history row lacks stored `expectStartTime`
- **THEN** that row MUST NOT be counted as an accuracy sample

### Requirement: Tapping an accuracy bar SHALL replace the in-card chart with that day’s prediction summary

When the user taps a day bar that has eligible samples, the client MUST replace the **same card’s chart region** with that day’s prediction summary (预计 vs 实际 per occurrence for that event root). The summary MUST NOT navigate to another route and MUST NOT be a modal/bottom sheet as the primary presentation. Tapping an empty day slot MUST NOT enter summary mode. The chart region MUST provide an explicit control to return to the 7-day accuracy bars (e.g. 「近7日」). 点有样本柱 MUST 在同卡图区替换为当日预测小结；MUST NOT 以跳转/弹层为主呈现；空日 MUST NOT 进入小结；MUST 提供返回柱图控件。

#### Scenario: Tap bar opens in-card summary

- **WHEN** the user taps a day bar with eligible samples on a vertical list prediction card
- **THEN** the card’s chart region shows that day’s expect-vs-actual summary list and no longer shows the 7-day bars

#### Scenario: Return to bars

- **WHEN** the user activates the in-card return control while summary mode is shown
- **THEN** the chart region shows the 7-day accuracy bars again

#### Scenario: Empty day tap ignored

- **WHEN** the user taps a day slot with no eligible samples
- **THEN** the chart region remains in bars mode

### Requirement: Trends center MUST NOT show prediction-accuracy overlays from the superseded change

The trends-center near-N-day **volume** bar chart MUST NOT display per-day prediction accuracy percent labels introduced by `trends-n-day-predict-accuracy`. Volume top labels for the selected day MAY remain. 趋势中心近 N 日量柱 MUST NOT 展示误落地的按日预测准确率顶标。

#### Scenario: Trends volume chart has no accuracy percent

- **WHEN** the user opens trends center and views the near-N-day volume bar chart
- **THEN** bars do not show accuracy percent labels above them
