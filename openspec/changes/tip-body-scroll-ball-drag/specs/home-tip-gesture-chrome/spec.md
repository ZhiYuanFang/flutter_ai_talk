## REMOVED Requirements

### Requirement: Expanded tip drag unit MUST include badge and card body

**Reason**: 展开态不再拖卡；拖动仅球态。  
**Migration**: 见本文件 ADDED「Expanded tip MUST NOT pan-drag」与「Tip ball MUST be the sole drag affordance」。

## ADDED Requirements

### Requirement: Expanded tip MUST NOT pan-drag the card or badge

While the tip is expanded, the client MUST NOT translate the tip card or top badge via pan gestures; the only expanded badge interaction MUST be tap-to-collapse into a floating ball. 展开态 **不得** 通过 pan 平移卡片或顶标；顶标在展开态 **仅** 允许点按折叠为浮空球。

#### Scenario: 展开拖正文不移卡

- **WHEN** tip 为 expanded
- **AND** 用户在正文区拖动
- **THEN** 卡片锚点 MUST 保持居中（或当前展开位置）不随拖平移
- **AND** 正文 MAY 滚动

#### Scenario: 顶标点折叠

- **WHEN** tip 为 expanded
- **AND** 用户点按顶标
- **THEN** tip MUST 进入球态（floating 或等价）
- **AND** MUST NOT 因此进陪伴

### Requirement: Tip ball MUST be the sole drag affordance for docking

After the tip is collapsed or docked as a ball on EdgeDockShell, the user MUST be able to drag that ball to snap to edges; docking MUST NOT require an expanded-card half-edge release. tip 折叠/贴边为球后，用户 **必须** 能拖该球吸附贴边；**不得** 要求展开卡过半松手才能贴边。

#### Scenario: 球可拖贴边

- **WHEN** tip 为 EdgeDock 球态
- **AND** 用户拖球至边缘并松手符合壳吸附规则
- **THEN** 球 MUST 进入 edge peek（或壳等价贴边态）
