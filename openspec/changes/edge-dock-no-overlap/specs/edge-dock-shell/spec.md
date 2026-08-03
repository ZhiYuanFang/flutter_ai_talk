## ADDED Requirements

### Requirement: Edge dock shell MUST apply occupancy-resolved placement on release

When an occupancy id is configured, after a drag ends (edge snap or floating settle) the shell MUST apply a placement that has been resolved against the shared occupancy registry so it does not overlap other registered balls. 配置了占位 id 时，拖动结束（贴边吸附或浮空落点）后，壳 **必须** 应用经共享占位表解冲突后的 placement，**不得** 与其它已注册球重叠。

#### Scenario: 松手不重叠

- **WHEN** 壳 A、B 均已注册占位
- **AND** 用户拖 A 松手到与 B 重叠的目标点
- **THEN** A 的最终视觉 placement MUST 不与 B 重叠

#### Scenario: 未配置占位 id

- **WHEN** 壳未配置 occupancy id
- **THEN** 壳 MAY 保持既有单球行为（兼容）；首页 tip/模式球 MUST 配置 id
