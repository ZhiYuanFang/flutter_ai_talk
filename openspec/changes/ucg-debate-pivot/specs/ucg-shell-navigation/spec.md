## ADDED Requirements

### Requirement: Square tab SHALL expose FAB for debate compose

The UCG square tab MUST render a floating action button that opens debate compose. FAB placement MUST NOT obstruct primary feed scroll or sub-tab pills.

广场 Tab MUST 提供辩论发帖 FAB。

#### Scenario: FAB 可见

- **WHEN** 用户位于广场 Tab 浏览 Feed

- **THEN** FAB SHALL 可见且点击打开 `UcgDebateComposeScreen`

## MODIFIED Requirements

### Requirement: UCG shell bottom dock SHALL not include compose entry

The bottom navigation dock MUST provide tabs for square, messages, and profile (or equivalent baseline tabs) but MUST NOT include a center or dedicated「发帖/发布」compose action. Publishing debates MUST occur only via square FAB.

底部 Dock MUST NOT 包含发帖入口；发帖仅经广场 FAB。

#### Scenario: Dock 无发布按钮

- **WHEN** 用户查看 UCG Shell 底部 Dock

- **THEN** MUST NOT 存在 compose/发布 按钮或 Tab
