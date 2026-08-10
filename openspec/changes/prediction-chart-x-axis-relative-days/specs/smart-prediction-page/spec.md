## ADDED Requirements

### Requirement: Prediction chart X-axis SHALL use relative day labels for the last three calendar days

On smart prediction event line charts, bottom X-axis day labels SHALL use relative Chinese day names for the three local calendar days ending today: day-before-yesterday MUST show「前天」, yesterday MUST show「昨天」, and today MUST show「今天」。Any earlier day within the chart window MUST keep a compact calendar date label of the form `M/d` (month/day). This rule MUST apply in both list layout (seven-day window) and grid layout (three-day window); chart point windows, Y-axis visibility, and forecast toggles MUST remain unchanged by this requirement.

智能预测事件折线底部 X 轴：相对今天为 **前天 / 昨天 / 今天** 的三个本地自然日 **必须** 分别显示「前天」「昨天」「今天」；窗内更早之日 **必须** 仍为 `M/d`。该规则 **必须** 同时适用于列表（近 7 日）与网格（近 3 日）；取点窗口、Y 轴显隐、推演开关 **不得** 因本需求改变。

#### Scenario: 列表近七日混排刻度

- **WHEN** 布局为纵向列表且事件卡展示近 7 日折线
- **THEN** X 轴对应今天−6 … 今天−3 的刻度 MUST 为 `M/d` 形式日期
- **AND** 对应前天、昨天、今天的刻度 MUST 分别为「前天」「昨天」「今天」

#### Scenario: 网格近三日全相对日

- **WHEN** 布局为网格且事件卡展示近 3 日折线
- **THEN** X 轴三个日刻度 MUST 分别为「前天」「昨天」「今天」
- **AND** MUST NOT 仅用 `M/d` 代替该三日相对日文案
