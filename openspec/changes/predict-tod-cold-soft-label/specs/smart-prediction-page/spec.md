## ADDED Requirements

### Requirement: Hot non-appointment cards SHALL show low TOD confidence copy above countdown

When a hot (non-demo, non-skeleton) smart prediction card for a **non-appointment** catalog root shows a live next-occurrence countdown (or overdue countdown copy) driven by a computable prediction, and that prediction is marked time-of-day low-confidence per `event-interval-prediction`, the client MUST show the fixed copy 「此刻把握不足」 within the countdown block, above the countdown title/digits row. The client MUST NOT show that copy when the prediction is not marked time-of-day low-confidence, when histogram density guard is skipped for insufficient samples, for appointment roots, for demo-skeleton cards, when forecast is OFF, or when there is no computable prediction (including when the card shows 「补充大概多久一次」 instead of a countdown). Amount expect secondary copy（「预计约…」）MAY still appear; when both appear, the low-confidence copy MUST remain visible in the countdown block.

热态非骨架、**非预约**预测卡在展示由可计算预测驱动的下次倒计时（含逾期文案），且该预测按 `event-interval-prediction` 标记为钟点把握不足时，客户端 MUST 在倒计时区块内、倒计时标题/数字上方展示固定文案「此刻把握不足」。未标记把握不足、密度护栏因样本不足跳过、预约根、骨架卡、推演关闭、或无可计算预测（含展示「补充大概多久一次」而无倒计时）时 MUST NOT 展示该文案。用量 expect「预计约…」MAY 仍出现；两者同时出现时，把握不足文案 MUST 仍可见。

#### Scenario: 冷区软标展示文案

- **WHEN** 非预约热态卡有倒计时，且对应预测标记为钟点把握不足
- **THEN** 倒计时区块 MUST 展示「此刻把握不足」
- **AND** MUST 仍展示倒计时（或逾期文案）

#### Scenario: 热区候选不展示文案

- **WHEN** 非预约热态卡有倒计时，且对应预测未标记钟点把握不足
- **THEN** 卡上 MUST NOT 展示「此刻把握不足」

#### Scenario: 无预测不展示文案

- **WHEN** 非预约热态卡因不可预测展示「补充大概多久一次」或无倒计时
- **THEN** MUST NOT 展示「此刻把握不足」

#### Scenario: 预约卡不展示文案

- **WHEN** 预约热态卡展示 countdown
- **THEN** MUST NOT 因间隔直方图钟点把握不足展示「此刻把握不足」
