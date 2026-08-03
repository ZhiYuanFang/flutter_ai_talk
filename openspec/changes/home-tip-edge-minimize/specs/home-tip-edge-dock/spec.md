## ADDED Requirements

### Requirement: Expanded tip MUST be draggable and dockable on all four edges

While the tip panel is expanded and displayable, the user MUST be able to drag it within the home tip bounds; when the tip crosses a screen edge by more than half of its width (horizontal edges) or height (vertical edges) and the gesture ends, the client MUST minimize the tip into a Pangbao round icon sucked into that edge (left/right/top/bottom). 展开且可展示时用户 **必须** 可拖动 tip；松手时若贴边越过 tip **一半宽/高**，客户端 **必须** 将其最小化为胖宝圆标并吸入该边（四边均可）。

#### Scenario: 右缘过半吸入

- **WHEN** 用户将展开 tip 拖向右缘且越过半宽阈值后松手
- **THEN** tip MUST 进入 docked 态并以圆标半嵌于右缘
- **AND** tip 文本内容 MUST 仍保留（非 dismiss）

#### Scenario: 未过半回弹居中

- **WHEN** 用户拖动展开 tip 但未达任一边过半阈值后松手
- **THEN** tip MUST 保持 expanded 并回到居中（或等价居中复位）

### Requirement: Docked tip MUST be expandable and MUST NOT equal dismiss

A docked tip MUST remain associated with the current tip content; tapping the edge icon (or an equivalent expand gesture) MUST restore an expanded presentation. Tapping「关闭」MUST still dismiss to idle and MUST NOT be required to undock. docked tip **必须** 保留当前内容；点侧边圆（或等价展开手势）**必须** 恢复展开态。「关闭」**必须** 仍可 dismiss；展开 **不得** 依赖先关闭。

#### Scenario: 点圆展开

- **WHEN** tip 处于 docked
- **AND** 用户点击侧边胖宝圆标
- **THEN** tip MUST 变为 expanded 并可见卡片与下方按钮

#### Scenario: 关闭仍销毁

- **WHEN** tip 处于 expanded 或（若关闭在 docked 暴露）用户触发关闭
- **THEN** 面板 MUST 进入隐藏 idle 且后续旧 SSE MUST 被忽略（与既有 dismiss 语义一致）

### Requirement: New tip while docked MUST force center expand with entrance animation

When tip streaming restarts and `presentationGeneration` (or equivalent) advances while the tip UI is docked, the client MUST exit docked state, show the tip expanded and centered, and replay the elastic scale-in entrance when displayable text arrives. 当 tip UI 处于 docked 且新 tip 开始（呈现代数递增）时，客户端 **必须** 退出 docked，以 **居中 expanded** 展示，并在可展示文本到达时 **再播** 弹性入场。

#### Scenario: docked 中再次添加

- **WHEN** tip 已 docked
- **AND** 本机再次触发 tip `startStreaming`（呈现代数 +1）
- **THEN** UI MUST 离开 docked
- **AND** MUST 居中 expanded
- **AND** 当新 thinking/answer 非空时 MUST 再播入场弹性动画

### Requirement: Docked edge icon MUST use Pangbao flat round asset

The minimized edge icon and the expanded card’s top badge MUST use the same Pangbao flat round image asset (`assets/images/app_icon_round.png` / `kStartupIconAsset` or equivalent). 最小化侧边圆与展开态顶部圆标 **必须** 使用同一胖宝平拍圆图资产。

#### Scenario: 资产一致

- **WHEN** tip 处于 expanded 或 docked 且可见
- **THEN** 顶部圆标或侧边圆 MUST 展示该平拍圆图（圆形裁剪）
