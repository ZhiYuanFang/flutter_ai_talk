## ADDED Requirements

### Requirement: N-day trend bars SHALL show per-day prediction accuracy above each bar when samples exist

When the trends center presents the N-day volume overview bar chart for the currently selected event, the client MUST compute a prediction accuracy percentage for each local calendar day bucket in that chart. For each day that has at least one eligible history sample under the selected event’s catalog root, the client MUST render an integer percent label (e.g. `85%`) above that day’s volume bar. Days with zero eligible samples MUST omit the accuracy label (MUST NOT show a placeholder such as `—` solely for empty days). The existing selected-bar volume top label behavior MUST remain; accuracy labels MUST NOT replace volume top labels. Eligible samples MUST be history rows that already store a usable `expectStartTime` (positive unix seconds); the client MUST NOT replay interval prediction to invent `expect*` for scoring. A sample MUST count as a hit when the absolute difference between the record’s actual start unix seconds and `expectStartTime` is ≤ 1800 seconds; the day’s accuracy MUST be `round(100 * hits / sampleCount)`. Scope is the selected event root and the same N-day window as the volume bars. v1 MUST NOT require duration/amount dimensions in the score.

趋势中心展示当前选中事件的近 N 日总量柱图时，客户端 MUST 按图内每个本地自然日桶计算预测准确率。该日在选中事件目录根下至少有一条合格历史样本时，MUST 在该日量柱上方展示整数百分比（如 `85%`）。零合格样本的日子 MUST 省略准确率标签（MUST NOT 仅为空日画 `—`）。既有「仅选中柱显示量顶标」MUST 保留；准确率标签 MUST NOT 取代量顶标。合格样本 MUST 为已存可用 `expectStartTime`（正 unix 秒）的历史行；MUST NOT 重放间隔预测伪造 expect* 再计分。样本在 `|实际 start 秒 − expectStartTime| ≤ 1800` 时计命中；日准确率 MUST 为 `round(100 * hits / sampleCount)`。范围 MUST 为选中事件根且与量柱同一 N 日窗。v1 MUST NOT 要求把 duration/amount 维纳入得分。

#### Scenario: Day with hits shows percent above bar

- **WHEN** 近 7 日柱图某自然日有 2 条带 `expectStartTime` 的样本且均命中（误差 ≤30 分钟）
- **THEN** 该日量柱上方 MUST 显示 `100%`（或等价四舍五入结果）

#### Scenario: Empty expect day omits accuracy label

- **WHEN** 某自然日有喂养量柱但当日无任何带可用 `expectStartTime` 的样本
- **THEN** 该日 MUST NOT 显示准确率百分比标签
- **AND** 量柱与其它日准确率展示 MUST 仍可正常

#### Scenario: No replay for legacy rows

- **WHEN** 某日仅有无 expect* 的历史行
- **THEN** 这些行 MUST NOT 进入准确率分母
- **AND** MUST NOT 用当前算法回放填假 `expectStartTime` 后再计分

#### Scenario: Volume top label still selected-only

- **WHEN** 用户选中某一日量柱且该日有准确率标签
- **THEN** 量顶标（总量+单位）MUST 仍仅出现在选中柱
- **AND** 准确率 `%` MUST 不因「未选中」而从有样本的日子消失

#### Scenario: Miss outside thirty-minute window

- **WHEN** 某日 1 条样本 `|actual − expectStartTime| = 1801` 秒
- **THEN** 该样本 MUST 计未命中
- **AND** 若仅此一条，当日准确率 MUST 为 `0%`
