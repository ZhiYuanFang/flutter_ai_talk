## ADDED Requirements

### Requirement: Edge dock occupancy MUST register balls and reject overlapping placements

The system MUST maintain a shared occupancy registry for edge-dock balls; a proposed placement for a registered ball MUST be resolved so that its circle does not overlap any other registered ball by less than diameter plus a minimum gap. 系统 **必须** 维护共享贴边球占位注册表；对已注册球提出的 placement **必须** 解析为与其它已注册球圆心距不小于 diameter+最小间隙。

#### Scenario: 同边吸附避开 sticky

- **WHEN** sticky 球已在右边 along≈0.75
- **AND** 非 sticky 球松手欲吸附右边且与 sticky 重叠
- **THEN** 协调器 MUST 返回不重叠的 placement（调整 along 或换边/浮空）
- **AND** sticky 球 placement MUST NOT 被改写

#### Scenario: 浮空圆心互斥

- **WHEN** 两球均为 floating
- **AND** 拖动球松手圆心落入另一球直径+间隙内
- **THEN** 协调器 MUST 将拖动球外推至不重叠位置

### Requirement: Occupancy MUST support sticky priority

Registered balls MAY be marked sticky; when resolving conflicts, the resolver MUST treat sticky balls as immovable obstacles and MUST adjust only the non-sticky (or currently resolving) ball. 已注册球 **可** 标记 sticky；解冲突时 sticky **必须** 视为不可移动障碍，**必须** 只调整非 sticky（或当前解析中的）球。

#### Scenario: 模式球 sticky

- **WHEN** 模式球以 sticky 注册
- **AND** tip 球拖向模式球位置松手
- **THEN** tip 最终位置 MUST 不与模式球重叠
- **AND** 模式球位置 MUST 不变
