## ADDED Requirements

### Requirement: Portrait smart prediction card SHALL show read-only missed-cycle tips

On a **portrait** hot (non-demo, non-accuracy-only) smart prediction event card for a **non-appointment** root, when the live prediction carries a non-empty missed-cycle tip list from `predict-missed-cycle-reanchor`, the client MUST render a single read-only caption row between the「上一次」occurrence row（when present）and the countdown / estimated-clock block. The row MUST use the fixed prefix `可能漏记：` followed by each tip formatted with `formatRelativeCalendarDayAndTime`（or a thin wrapper of that helper; today MAY omit the day word per existing last-at conventions）, joined by ` · `. The row MUST NOT be tappable, MUST NOT open add/edit flows, and MUST NOT present the tips as recorded `lastAt`. In **landscape** orientation the client MUST NOT render this row. Feeding next-predict glass card, next-3-hours timeline, and home widget MUST NOT render this missed-tip row.

竖屏热态非预约智能预测卡在有漏记 tip 时，MUST 在「上一次」与倒计时之间只读展示 `可能漏记：…`（相对自然日时分、` · ` 连接）；MUST NOT 可点或冒充真记录；横屏 / 玻璃卡 / 3h / Widget MUST NOT 展示该行。

#### Scenario: 竖屏展示漏记行

- **WHEN** 竖屏热态非预约预测卡有 live nextAt，且 tip 列表为 11:05 与 14:20（同日本地日）
- **THEN** 卡上 MUST 出现只读文案 `可能漏记：11:05 · 14:20`（今日省略日词时）
- **AND** 该行 MUST 位于「上一次」行下方、倒计时/预计区块上方（有「上一次」时）

#### Scenario: 横屏不展示

- **WHEN** 横屏智能预测卡同一根带有非空 tip 列表
- **THEN** 客户端 MUST NOT 渲染「可能漏记」行

#### Scenario: 无 tip 不占位

- **WHEN** 竖屏热态卡 live 预测 tip 列表为空
- **THEN** 客户端 MUST NOT 渲染「可能漏记」行或空占位

#### Scenario: 不可点补录

- **WHEN** 用户点按「可能漏记」行文案
- **THEN** 客户端 MUST NOT 因此打开记事编辑 / 补充上一次 / 预填 add sheet
