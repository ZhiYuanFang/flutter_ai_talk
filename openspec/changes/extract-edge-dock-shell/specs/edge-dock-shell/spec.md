## ADDED Requirements

### Requirement: Edge dock shell MUST support peek, engaged, and floating placements

The shared edge-dock shell MUST model at least edge peek (semicircle on an edge), edge engaged (full circle near edge), and floating (draggable full circle inside bounds), with configurable diameter and along-edge position. 共享贴边壳 **必须** 支持至少贴边半圆 peek、贴边全圆 engaged、屏内浮空 floating，并支持可配置直径与沿边位置。

#### Scenario: 半圆贴边展示

- **WHEN** 壳处于 edge peek 且指定 edge/along
- **THEN** 视觉 MUST 为该边半嵌圆（Clip 半圆或等价）
- **AND** 命中热区 MUST 向屏内扩大（不得仅等于半圆可见像素）

### Requirement: Edge dock shell MUST lock page scroll on pointer down

While a pointer is down on the shell hittable target, the shell MUST invoke an occupation callback so the host can disable PageView horizontal scrolling until pointer up/cancel. 指针在壳热区按下期间，壳 **必须** 回调占用通知供宿主禁用 PageView 横滑，直至抬起或取消。

#### Scenario: 按下即占用

- **WHEN** 用户在壳热区内 pointerDown
- **THEN** 壳 MUST 发出 occupied=true（或等价）
- **WHEN** pointerUp 或 cancel
- **THEN** 壳 MUST 发出 occupied=false

### Requirement: Edge dock shell MUST allow pull-in or tap to leave peek

From edge peek, a tap OR accumulated inward drag past a threshold MUST transition toward engaged/floating or invoke a host engage callback; the shell MUST NOT rely on a single-frame delta alone for pull-in. 从 peek 态，点按或**累计**向内拖过阈值 **必须** 能离开 peek（engaged/floating 或宿主 engage 回调）；**不得** 仅依赖单帧 delta。

#### Scenario: 慢速向内拉可离开 peek

- **WHEN** 壳为 edge peek
- **AND** 用户向屏内缓慢拖动且累计向内位移超过阈值
- **THEN** 壳 MUST 离开 peek（进入 engaged/floating 或触发宿主展开回调）

#### Scenario: 点按离开 peek

- **WHEN** 壳为 edge peek 且用户点按热区
- **THEN** 壳 MUST 按宿主配置 engage 或触发 onTap/onEngage

### Requirement: Host features MUST supply only content and business callbacks

Mode-cycle, tip content, and persistence MUST remain outside the shell; the shell MUST accept a child widget and placement/tap/occupation callbacks only. 模式切换、tip 内容与持久化 **必须** 留在宿主；壳 **只** 接受 child 与位置/点击/占用回调。

#### Scenario: 壳无模式文案

- **WHEN** 仅挂载壳而不提供模式业务
- **THEN** 壳 MUST NOT 自身依赖 `HomeInputChannel` 或 tip SSE
