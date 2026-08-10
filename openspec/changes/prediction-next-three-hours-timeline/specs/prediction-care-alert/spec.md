## ADDED Requirements

### Requirement: Next-3-hours timeline placement relative to care-alert card

When the next-3-hours timeline is shown on the smart prediction page, it MUST be placed below the care-alert card area and above the event cards area. The timeline MUST NOT require the care-alert filtered list to be non-empty.

「接下来3小时」时间线展示时 **必须** 位于留意卡片区下方、事件卡片区上方；**不得** 要求留意过滤列表非空。

#### Scenario: 顺序

- **WHEN** 时间线有段落（无论留意是否为空态）
- **THEN** 页面自上而下 MUST 为：留意卡片区 → 接下来3小时时间线（若有）→ 事件卡片区
