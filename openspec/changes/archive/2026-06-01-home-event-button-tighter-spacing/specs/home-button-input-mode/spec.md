## MODIFIED Requirements

### Requirement: 两行横向事件网格

The system SHALL render the event catalog as **two horizontal scrollable rows** of cells in button mode, each cell showing **logo above name** using event branding (`EventLogo`, `color`). 按钮模式下必须使用**两行**可横向滚动的列表展示目录事件；每个 cell **上图下文**（logo + 名称），颜色来自事件 `color`。

#### Scenario: 目录 N 个有效事件分两行

- **WHEN** 按钮模式激活且目录有 N 个可展示事件
- **THEN** 第一行展示前 ⌈N/2⌉ 项，第二行展示其余项（顺序与目录列表一致）

#### Scenario: 相邻按钮水平间距

- **WHEN** 按钮模式展示横向事件按钮列表
- **THEN** 相邻 cell 之间的水平间距 MUST 不大于 **4** logical pixels（`kHomeEventButtonColumnGap`）
- **AND** 单列 cell 宽度 MUST 不大于 **64** logical pixels（`kHomeEventButtonColumnWidth`），以保证同屏可见更多按钮且名称仍可读

#### Scenario: 按钮 cell 内容与点击

- **WHEN** 用户查看底部事件按钮
- **THEN** 每个 cell MUST 仍展示 logo（约 40px）与最多 2 行事件名，且整 cell 可点击触发与原规格一致的行为
