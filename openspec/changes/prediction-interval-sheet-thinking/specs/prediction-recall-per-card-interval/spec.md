## MODIFIED Requirements

### Requirement: Per-card interval recall SHALL apply when hot state lacks prediction but has lastAt

When the smart prediction page renders a real (non-demo-skeleton) prediction event card for a root event whose forecast is enabled, whose merged history provides a non-null `lastAt`, and whose local predictor returns no `prediction`, the card MUST show a full-width event-accent heartbeat `FilledButton` (same animation pattern as the in-timer「停止」button) inviting the user to supply a typical interval. Activating it MUST open a glass bottom sheet for「大概多久一次」that starts with the interval wheel picker (minimum 15 minutes, same step table as recall onboarding) whose title MUST show the event logo and `{eventName}·大概多久一次`. On confirm of a valid interval, the client MUST upsert a `PredictionRecallSeed` anchored at the card’s `lastAt` with the chosen interval and synthesized occurrence points, MUST NOT prompt for last occurrence time in this path, MUST NOT write feeding history, and MUST NOT issue care-alert or tip HTTP; the sheet MUST then enter the in-sheet thinking phase defined by `prediction-interval-sheet-thinking` instead of dismissing immediately. When `lastAt` is null, forecast is disabled, a prediction already exists, or the row is a demo skeleton, the client MUST NOT show this interval control. The client MUST NOT introduce an interval-only draft seed without `lastAt`.

当智能预测页渲染热态（非 demo 骨架）事件卡，且该根推演开启、合并历史有非空 `lastAt`、本地推演无 `prediction` 时，卡片 **必须** 展示与计时「停止」同风格的全宽事件色心跳 `FilledButton` 引导补充典型间隔；点击 **必须** 打开「大概多久一次」玻璃 Sheet，初始为间隔滚轮（最小 15 分钟，与 recall onboarding 步进一致），标题 **必须** 含事件 Logo 与 `{eventName}·大概多久一次`。确认合法间隔后，客户端 **必须** 以卡片 `lastAt` 为锚 upsert 回忆种子并合成发生点，**不得** 在此路径再选上次时间、**不得** 写喂养历史、**不得** 打留意/tip HTTP；Sheet **必须** 进入 `prediction-interval-sheet-thinking` 规定的同层思考态，**不得** 在确认时立刻关闭。当 `lastAt` 为空、推演关闭、已有 prediction 或为 demo 骨架时，**不得** 展示该间隔控件。**不得** 引入无 `lastAt` 的仅间隔草稿种子。

#### Scenario: 有 lastAt 仅选间隔

- **WHEN** 用户查看某根事件卡且 `forecastEnabled == true`、`prediction == null`、`lastAt != null`
- **THEN** 卡片 MUST 展示全宽心跳 `FilledButton`「补充大概多久一次」
- **AND** 点击 MUST 打开标题为 `{EventLogo}{eventName}·大概多久一次` 的间隔滚轮 Sheet
- **AND** MUST NOT 要求选择上次发生/结束时间

#### Scenario: 确认后种子生效且进入思考

- **WHEN** 用户在 Sheet 中选择有效间隔并确认
- **THEN** 客户端 MUST upsert 该根的 `PredictionRecallSeed`
- **AND** Sheet MUST 进入同层思考态（不得立刻 dismiss）
- **AND** 该卡 MUST 在刷新后可展示 countdown / nextAt
- **AND** MUST NOT 经喂养 POST 写入历史

#### Scenario: 无 lastAt 不展示间隔

- **WHEN** 热态某根卡 `forecastEnabled == true`、`prediction == null`、`lastAt == null`
- **THEN** 「补充大概多久一次」MUST NOT 展示

#### Scenario: demo 骨架不展示

- **WHEN** 预测页处于 demo 骨架行（无真实 `onToggle` / 冷态骨架）
- **THEN** per-card 间隔控件 MUST NOT 展示

#### Scenario: 关推演不展示间隔

- **WHEN** 热态某根卡 `forecastEnabled == false`
- **THEN** per-card 间隔控件 MUST NOT 展示
