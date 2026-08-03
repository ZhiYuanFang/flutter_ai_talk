## MODIFIED Requirements

### Requirement: Docked tip MUST be expandable and MUST NOT equal dismiss

A tip ball on the shared edge-dock shell MUST remain associated with tip content. Peek tap MUST only reveal the full circle via shell baseline engage; expanded tip chrome MUST restore on engaged/floating tap or on pull-business after pull-in threshold. Dismiss via「关闭」remains separate. Host tip code MUST NOT implement a separate peek-tap expand path. tip 球 **必须** 保留 tip 内容。peek 点按 **必须** 仅经壳基线露出全圆；展开卡 **必须** 在 engaged/floating 点按，或拉满后的拉满业务回调中恢复。「关闭」仍为 dismiss。宿主 tip **不得** 自写半圆点按展开分支。

#### Scenario: 点半圆只露出全圆

- **WHEN** tip 球为 edge peek
- **AND** 用户点按热区
- **THEN** tip 球 MUST 变为 edge engaged（全圆）
- **AND** tip MUST NOT 直接变为 expanded

#### Scenario: 点全圆或浮空球展开

- **WHEN** tip 球为 edge engaged 或 floating
- **AND** 用户点按热区
- **THEN** tip MUST 变为 expanded

#### Scenario: 向内拉满可自动展开

- **WHEN** tip 球为 edge peek
- **AND** 用户向屏内累计拖过壳阈值
- **THEN** tip MUST 经壳 engage 后触发拉满业务并变为 expanded（或等价先全圆再立即展开）
- **AND** 该路径 MUST 使用壳基线拉满回调，MUST NOT 为 tip 单独实现弱拉出

#### Scenario: 关闭仍为 dismiss

- **WHEN** tip 为 expanded 且用户点「关闭」
- **THEN** tip MUST dismiss
- **AND** MUST NOT 仅因曾 dock/engage 而被视为已 dismiss
