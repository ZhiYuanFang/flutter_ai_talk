## ADDED Requirements

### Requirement: Per-card interval recall SHALL apply when hot state lacks prediction but has lastAt

When the smart prediction page renders a real (non-demo-skeleton) prediction event card for a root event whose forecast is enabled, whose merged history provides a non-null `lastAt`, and whose local predictor returns no `prediction`, the card MUST show a full-width event-accent heartbeat `FilledButton` (same animation pattern as the in-timer「停止」button) inviting the user to supply a typical interval. Activating it MUST open a glass bottom sheet with only the「大概多久一次」wheel picker (minimum 15 minutes, same step table as recall onboarding) whose title MUST show the event logo and `{eventName}·大概多久一次`. On confirm, the client MUST upsert a `PredictionRecallSeed` anchored at the card’s `lastAt` with the chosen interval and synthesized occurrence points, MUST NOT prompt for last occurrence time in this path, MUST NOT write feeding history, and MUST NOT issue care-alert or tip HTTP. After upsert, the card MUST reflect an upcoming prediction on the next rows rebuild.

当智能预测页渲染热态（非 demo 骨架）事件卡，且该根推演开启、合并历史有非空 `lastAt`、本地推演无 `prediction` 时，卡片 **必须** 展示与计时「停止」同风格的全宽事件色心跳 `FilledButton` 引导补充典型间隔；点击 **必须** 打开仅含「大概多久一次」滚轮的玻璃 Sheet，标题 **必须** 含事件 Logo 与 `{eventName}·大概多久一次`（最小 15 分钟，与 recall onboarding 步进一致）；确认后 **必须** 以卡片 `lastAt` 为锚 upsert 回忆种子并合成发生点，**不得** 在此路径再选上次时间、**不得** 写喂养历史、**不得** 打留意/tip HTTP；upsert 后下一次行重建 **必须** 展示 upcoming 预测。

#### Scenario: 有 lastAt 仅选间隔

- **WHEN** 用户查看某根事件卡且 `forecastEnabled == true`、`prediction == null`、`lastAt != null`
- **THEN** 卡片 MUST 展示全宽心跳 `FilledButton`「补充大概多久一次」
- **AND** 点击 MUST 打开标题为 `{EventLogo}{eventName}·大概多久一次` 的仅间隔滚轮 Sheet
- **AND** MUST NOT 要求选择上次发生/结束时间

#### Scenario: 确认后种子生效

- **WHEN** 用户在 Sheet 中选择有效间隔并确认
- **THEN** 客户端 MUST upsert 该根的 `PredictionRecallSeed`
- **AND** 该卡 MUST 在刷新后展示 countdown / nextAt
- **AND** MUST NOT 经喂养 POST 写入历史

#### Scenario: demo 骨架不展示

- **WHEN** 预测页处于 demo 骨架行（无真实 `onToggle` / 冷态骨架）
- **THEN** per-card 间隔控件 MUST NOT 展示

#### Scenario: 空库量身定做优先

- **WHEN** `predictionRecallEmptyHistoryEligible` 为 true 且量身定做 Dialog 会话可见或待展示
- **THEN** per-card 控件 MAY 被 Dialog 遮挡
- **AND** 不得与 Dialog 重复写同一根的种子（以 Dialog 流程为准直至会话结束）
