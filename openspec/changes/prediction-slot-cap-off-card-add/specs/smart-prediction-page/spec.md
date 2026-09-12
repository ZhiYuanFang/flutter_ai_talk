## MODIFIED Requirements

### Requirement: Sparse hot cards SHALL offer heartbeat add-last CTA when forecast enabled and lastAt missing
热态预测卡在推演开启、`prediction == null` 且 `lastAt == null` 时，**必须** 展示与间隔 CTA /「停止」同风格的全宽事件色心跳控件「补充上一次」；点击 **必须** 走与点卡相同的加事件路径（网格含 `confirmDirectLeafBeforeAdd: true`）且 intent 为 supplement。`lastAt == null` 时 **不得** 展示间隔回忆 CTA。推演关闭时 **不得** 展示「补充上一次」与间隔 CTA。推演关闭时整卡点击 **必须** 仍可加喂养，且 **必须** 使用 `EventRecordIntent.add`（**不得** 使用 supplement）；该行为由 `prediction-off-card-add` 约束。When forecast is enabled, prediction is null, and lastAt is null, the card MUST show the heartbeat「补充上一次」CTA wired to the same path as card tap with supplement intent. When forecast is disabled, those CTAs MUST be hidden, but card-body tap MUST still add via `EventRecordIntent.add` (not supplement).

#### Scenario: 无 lastAt 展示补充上一次
- **WHEN** 热态某根卡 `forecastEnabled == true`、`lastAt == null`、`prediction == null`
- **THEN** 卡上 MUST 出现「补充上一次」心跳按钮
- **AND** MUST NOT 出现「补充大概多久一次」

#### Scenario: 点补充上一次等同点卡补齐
- **WHEN** 用户点击该「补充上一次」
- **THEN** App MUST 走与点该卡相同的 `handleEventGridTap` 补齐路径（supplement）

#### Scenario: 关推演无补齐 CTA
- **WHEN** 热态某根卡 `forecastEnabled == false`
- **THEN** 卡上 MUST NOT 出现「补充上一次」或「补充大概多久一次」

#### Scenario: 关推演点卡仍可 add
- **WHEN** 热态某根卡 `forecastEnabled == false` 且非计时中，用户点击卡片主体
- **THEN** App MUST 以 `EventRecordIntent.add` 打开加喂养流程
- **AND** MUST NOT 走 supplement 补齐引导
