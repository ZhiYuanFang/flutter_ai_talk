## MODIFIED Requirements

### Requirement: Expanded tip MUST be draggable and dockable on all four edges

An expanded tip MUST NOT dock by dragging the expanded card past a half-edge threshold. Docking to edges MUST occur only after the tip is in ball mode (collapsed or already docked) via the shared edge-dock shell. 展开 tip **不得** 靠拖展开卡过半宽/高松手贴边；贴边 **必须** 仅在球态经共享 EdgeDock 壳完成。

#### Scenario: 展开过半不贴边

- **WHEN** tip 为 expanded
- **AND** 用户在正文或顶标尝试拖向屏幕边缘
- **THEN** tip MUST NOT 因此切换为 edge peek
- **AND** 顶标点按仍可折叠为球后再拖贴边
