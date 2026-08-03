## MODIFIED Requirements

### Requirement: Expanded tip MUST be draggable and dockable on all four edges

While the tip panel is expanded and displayable, the user MUST be able to drag it (including via the top badge) within the home tip bounds; when the tip crosses a screen edge by more than half of its width or height and the gesture ends, the client MUST hand the tip ball to the shared edge-dock shell in edge peek on that edge. Badge tap MUST still collapse in place (not edge peek) per gesture-chrome. 展开 tip **必须** 可拖（含顶标）；松手过半宽/高时 **必须** 将球交由共享 EdgeDock 壳进入该边 peek。点顶标仍原地折叠，**不得** 仅因此进入贴边 peek。

#### Scenario: 右缘过半交壳

- **WHEN** 用户将展开 tip 拖向右缘且越过半宽阈值后松手
- **THEN** tip 球 MUST 由 EdgeDockShell 以右缘 peek 展示
- **AND** tip 文本 MUST 仍保留

### Requirement: Docked tip MUST be expandable and MUST NOT equal dismiss

A tip ball in edge peek (or shell floating collapsed) MUST remain associated with tip content; tap or pull-in engage on the shell MUST restore expanded tip chrome. Dismiss via「关闭」remains separate. peek/浮空球 **必须** 保留 tip 内容；点按或向内拉 engage **必须** 恢复展开卡。「关闭」仍为 dismiss。

#### Scenario: 点贴边球展开

- **WHEN** tip 球为 edge peek
- **AND** 用户点按热区
- **THEN** tip MUST 变为 expanded

#### Scenario: 向内拉贴边球展开

- **WHEN** tip 球为 edge peek
- **AND** 用户向屏内累计拖过壳阈值
- **THEN** tip MUST 变为 expanded（对齐模式球离开 peek）
