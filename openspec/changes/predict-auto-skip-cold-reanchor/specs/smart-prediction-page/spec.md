## ADDED Requirements

### Requirement: Smart prediction cards MUST NOT offer manual overdue skip

Hot smart prediction cards MUST NOT present a「跳过本次」（or equivalent）control that persists a local missAnchor or otherwise advances prediction by a device-local skip action. Overdue and cold handling MUST rely on shared-history interval prediction（including at-most-one automatic cold reanchor）only. Soft low-confidence copy「此刻把握不足」MAY still appear when the prediction is marked time-of-day low-confidence.

热态智能预测卡 MUST NOT 展示「跳过本次」（或等价）控件以持久化本机 missAnchor 或其它仅本机跳档。逾期与冷区 MUST 仅依赖共享历史间隔预测（含至多一次自动换锚）。预测标记钟点把握不足时，「此刻把握不足」MAY 仍展示。

#### Scenario: 逾期卡无跳过按钮

- **WHEN** 非预约热态卡展示逾期预估时刻或倒计时
- **THEN** 卡上 MUST NOT 出现「跳过本次」

#### Scenario: 触顶仍冷可软标

- **WHEN** 非预约热态卡有倒计时且预测标记钟点把握不足
- **THEN** 倒计时区块 MUST 仍可展示「此刻把握不足」（含时刻态与标题同行规则，若已落地）

## REMOVED Requirements

### Requirement: Overdue non-appointment cards SHALL offer skip-this-prediction

**Reason**: 本机跳过无法多端一致；改由算法自动换锚。  
**Migration**: 移除按钮与 missAnchor 接线；见 `event-interval-prediction` 自动换锚 Requirement。
