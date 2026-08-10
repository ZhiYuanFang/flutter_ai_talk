## ADDED Requirements

### Requirement: Care alert engine SHALL evaluate all events against dual baselines

The client SHALL evaluate care alerts for all identifiable events in the prediction 7-day range window using (1) the baby's own 7-day baseline derived from that window and (2) an age-band expectation table when baby birth date is usable. When birth date is not usable, the engine MUST use only the own 7-day baseline and MUST treat expectation fields as unused. The engine MUST NOT depend on `event_next_predictor` internals for scoring, and MUST NOT issue HTTP solely to evaluate alerts.

客户端 **必须** 对 7 日 range 内可识别事件用自身 7 日基线评估；月龄可用时 **必须** 叠加月龄期望表；月龄不可用时 **仅** 自身基线。评估 **不得** 依赖推演内部打分，**不得** 仅为评估发起 HTTP。

#### Scenario: 未知月龄仅自身基线

- **WHEN** 宝宝生日不可用且某事件 7 日间隔样本 ≥ 3、最近间隔相对中位显著拉长
- **THEN** 引擎 MUST 仍可产出「间隔拉长」候选
- **AND** 原因结构中期望字段 MUST 标为未使用

#### Scenario: 评估不发起 HTTP

- **WHEN** 智能预测页触发护理留意评估
- **THEN** 客户端 MUST NOT 仅为该评估新增网络请求（复用已有 range 数据）

### Requirement: Alert type priority SHALL be elongated interval then long active then sudden absence

When multiple candidates pass thresholds, the client SHALL select at most one alert with type priority **elongated interval** > **long active** > **sudden absence**. Within the same type, the client MUST pick the candidate with the highest deviation score. When no candidate passes thresholds, the result MUST be null (no alert).

多候选时类型优先级 **必须** 为间隔拉长 > 进行中过久 > 突然消失；同类取偏离最大；无过阈值候选时结果 **必须** 为 null。

#### Scenario: 间隔拉长压过进行中过久

- **WHEN** 事件 A 触发间隔拉长且事件 B 触发进行中过久
- **THEN** Top1 MUST 为事件 A 的间隔拉长

#### Scenario: 无候选

- **WHEN** 全部事件均未过阈值
- **THEN** 评估结果 MUST 为 null

### Requirement: Elongated interval rule SHALL require minimum samples

The elongated-interval rule SHALL require at least three occurrence samples in the 7-day window to form a median gap baseline. It MUST fire when the latest gap is significantly longer than that baseline and/or (when expectation exists) exceeds the age-band max expected gap, per design thresholds.

间隔拉长 **必须** 至少 3 次 occurrence 才建中位基线，并按 design 阈值相对基线与/或期望上限触发。

#### Scenario: 样本不足不报间隔拉长

- **WHEN** 某事件 7 日内仅 2 次 occurrence
- **THEN** 引擎 MUST NOT 因间隔拉长产出该事件候选

### Requirement: Care alert detail SHALL expose structured reason fields

The alert detail presentation SHALL include structured fields: alert type, own-baseline metrics, age-expectation metrics (or unused), and observed metrics that caused the fire. The copy tone MUST use「值得留意」framing and MUST NOT claim a medical diagnosis.

详情 **必须** 结构化展示类型、自身基线、月龄期望（或未使用）、实际观测；语气 **必须** 为「值得留意」，**不得** 宣称医疗诊断。

#### Scenario: 详情含对比数字

- **WHEN** 用户打开一条间隔拉长预警的详情
- **THEN** 页面 MUST 展示自身中位间隔与最近间隔（及期望上限若已使用）
- **AND** MUST NOT 使用诊断性病名恐吓文案
