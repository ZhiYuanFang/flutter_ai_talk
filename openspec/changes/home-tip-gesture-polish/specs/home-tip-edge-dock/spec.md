## MODIFIED Requirements

### Requirement: Expanded tip MUST be draggable and dockable on all four edges

While the tip panel is expanded and displayable, the user MUST be able to drag it (including via the top badge) within the home tip bounds; when the tip crosses a screen edge by more than half of its width (horizontal edges) or height (vertical edges) and the gesture ends, the client MUST minimize the tip into a Pangbao round icon sucked into that edge (left/right/top/bottom). Edge docking MUST NOT be triggered by a mere tap on the top badge (badge tap collapses in place per `home-tip-gesture-chrome`). 展开且可展示时用户 **必须** 可拖动 tip（**含顶标**）；松手时若贴边越过 tip **一半宽/高**，客户端 **必须** 将其最小化为胖宝圆标并吸入该边。仅点击顶标 **不得** 触发贴边吸入（点标原地折叠见 `home-tip-gesture-chrome`）。

#### Scenario: 右缘过半吸入

- **WHEN** 用户将展开 tip 拖向右缘且越过半宽阈值后松手
- **THEN** tip MUST 进入 docked 态并以圆标半嵌于右缘
- **AND** tip 文本内容 MUST 仍保留（非 dismiss）

#### Scenario: 未过半回弹或保持偏移

- **WHEN** 用户拖动展开 tip 但未达任一边过半阈值后松手
- **THEN** tip MUST 保持 expanded（可回弹居中或保留实现约定的非贴边复位；**不得** 因松手进入 docked）

#### Scenario: 点顶标不贴边

- **WHEN** 用户点击顶标且未拖动超过 slop
- **THEN** tip MUST NOT 仅因此进入 edge docked
