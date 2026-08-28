## ADDED Requirements

### Requirement: Prediction cards SHALL offer interval-only recall when prediction is missing but lastAt exists

On the smart prediction page, for each real prediction event card (not demo skeleton) where forecast is enabled, `SmartPredictionRow.prediction` is null, and `SmartPredictionRow.lastAt` is non-null, the card chrome MUST include a visible control to open the per-card interval recall flow defined in `prediction-recall-per-card-interval`. The control MUST NOT appear when forecast is disabled, when a prediction exists, when `lastAt` is null, or on demo skeleton cards.

智能预测页上，对每条真实预测事件卡（非 demo 骨架），当推演开启、`prediction` 为空且 `lastAt` 非空时，卡片 chrome **必须** 包含打开 per-card 仅间隔回忆流程的可见控件；推演关闭、已有 prediction、`lastAt` 为空或 demo 骨架时 **不得** 展示该控件。

#### Scenario: 热态单事件不足样本

- **WHEN** 用户已绑定且有真历史（非空库）且某根卡 `prediction == null` 且 `lastAt != null` 且推演开启
- **THEN** 该卡 MUST 展示间隔回忆控件
- **AND** 点击 MUST 进入仅间隔 Sheet

#### Scenario: 已有 prediction 不展示

- **WHEN** 某根卡已有 `prediction` 与 countdown
- **THEN** 该卡 MUST NOT 展示间隔回忆控件

#### Scenario: 关闭推演不展示

- **WHEN** 用户关闭该根推演
- **THEN** 该卡 MUST NOT 展示间隔回忆控件（与置灰卡一致）
