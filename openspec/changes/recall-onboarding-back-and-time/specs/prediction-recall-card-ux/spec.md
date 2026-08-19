## MODIFIED Requirements

### Requirement: Recall card SHALL show child events as read-only containment

On each prediction-recall onboarding root card, when the catalog has one or more real child events under that root, the client MUST show a read-only section titled to the effect of「该事件包含」listing those children. Each listed child MUST show that child’s `EventLogo` (or equivalent event logo widget) beside its name. The section MUST NOT use button morphology (`Chip`, `ChoiceChip`, `InkWell` tap targets, or equivalent selectable chips). The client MUST NOT require the user to select a specific child. When the root has no children, that section MUST NOT be shown. The recall seed written on confirm MUST use the root event id as `leafEventId` (MUST NOT depend on a user-selected leaf).

量身定做根卡片在存在真实子事件时 **必须** 只读展示「该事件包含」；每条子事件 **必须** 在名称旁展示该子事件 logo，**不得** 使用 `Chip` / `ChoiceChip` / 可点 InkWell 等按钮形态，**不得** 强制用户选择某一种；无子事件时 **不得** 展示该区块；确认写入种子时 `leafEventId` **必须** 为根事件 id。

#### Scenario: 有子事件只读展示

- **WHEN** 当前根在目录中有至少一个子事件
- **THEN** 卡片 MUST 展示「该事件包含」及子事件名称，且 MUST NOT 提供可选中态

#### Scenario: 子事件带 logo 且非按钮

- **WHEN** 「该事件包含」区正在展示子事件
- **THEN** 每个子事件 MUST 显示其事件 logo 与名称
- **AND** UI MUST NOT 以 Material Chip / ChoiceChip 或等价可点按钮形态展示这些子事件

#### Scenario: 无子事件隐藏

- **WHEN** 当前根没有子事件
- **THEN** UI MUST NOT 展示「该事件包含 / 当时是哪一种」区块
