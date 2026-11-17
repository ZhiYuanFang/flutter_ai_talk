## ADDED Requirements

### Requirement: Client MUST NOT present interval-recall CTA or seed stack

The client MUST NOT show「补充大概多久一次」or equivalent interval-recall controls on smart prediction cards (including adjust-interval affordances that reopen the same flow). The client MUST NOT persist or upsert `PredictionRecallSeed` (or equivalent), MUST NOT open the per-card「大概多久一次」interval glass sheet, and MUST NOT feed recall-seed intervals into the prediction pipeline, home tip, next-3-hours, or desktop widget as a substitute for affinity `nextAt`. When a row has no affinity `nextAt`, the client MUST use affinity-progress chrome per `predict-affinity-progress` (or equivalent) and MUST NOT invent a seed-based countdown presented as a forecast. 客户端 MUST NOT 展示「补充大概多久一次」及等价调间隔入口；MUST NOT 持久化/upsert 回忆种子；MUST NOT 打开 per-card 间隔玻璃 Sheet；MUST NOT 将种子间隔喂入预测管线 / tip / 3h / 桌面 widget 冒充亲和 nextAt。无亲和 nextAt 时 MUST 走亲和进度，MUST NOT 用种子倒计时冒充预测。

#### Scenario: 有 lastAt 无预测不出现间隔钮

- **WHEN** 热态非预约卡推演开启、真 `lastAt` 非空、亲和 `prediction` / `nextAt` 为空
- **THEN** UI MUST NOT 展示「补充大概多久一次」
- **AND** MUST NOT 展示仅用于改种子间隔的「调间隔」入口
- **AND** 卡面 MUST 按亲和进度（或其它非种子空态）呈现，MUST NOT 仅因旧种子 prefs 出现倒计时

#### Scenario: 管线无种子旁路

- **WHEN** 客户端构建智能预测行或 widget 同步输入
- **THEN** MUST NOT 读取或合并 `PredictionRecallSeed` / `recallIntervalsByRoot` 间隔旁路
- **AND** MUST NOT 将 `recall_seed_` 伪历史写入喂养池

#### Scenario: 预约补充下次仍可用

- **WHEN** 用户在预约预测卡上需要补充下次时间
- **THEN** 客户端 MAY 展示「补充下次」并打开专用预约 sheet
- **AND** MUST NOT 因此恢复间隔回忆 CTA
