## MODIFIED Requirements

### Requirement: Edge dock shell MUST allow pull-in or tap to leave peek

From edge peek, a tap MUST transition only to edge engaged (full circle near the edge) and MUST NOT invoke host business callbacks. Accumulated inward drag past a threshold MUST engage and MAY then invoke an optional host pull-business callback; the shell MUST NOT rely on a single-frame delta alone for pull-in. Host business for mode-cycle or tip expand MUST NOT be wired to peek tap. 从 peek 态，点按 **必须** 仅进入 engaged（贴边全圆），**不得** 调用宿主业务回调。累计向内拖过阈值 **必须** engage，并 **可** 再调用可选的拉满业务回调；**不得** 仅依赖单帧 delta。模式切换、tip 展开等宿主业务 **不得** 挂在 peek 点按上。

#### Scenario: 慢速向内拉离开 peek

- **WHEN** 壳为 edge peek
- **AND** 用户向屏内缓慢拖动且累计向内位移超过阈值
- **THEN** 壳 MUST 进入 edge engaged（全圆露出）
- **AND** 若宿主提供了拉满业务回调则 MUST 调用该回调；未提供则 MUST NOT 臆造业务

#### Scenario: 点按仅 engage

- **WHEN** 壳为 edge peek 且用户点按热区（未拖过 slop）
- **THEN** 壳 MUST 进入 edge engaged
- **AND** 壳 MUST NOT 调用 `onInteractiveTap` 或拉满业务回调

#### Scenario: 全圆点按才业务

- **WHEN** 壳为 edge engaged 或 floating
- **AND** 用户点按热区（未拖过 slop）
- **THEN** 壳 MUST 调用宿主 `onInteractiveTap`（若已提供）

## ADDED Requirements

### Requirement: Edge dock shell MUST NOT expose peek-tap business bypass

The shell MUST NOT provide a configuration that maps peek tap directly to host expand/cycle (or equivalent business). Features MUST obtain peek-tap→full-circle behavior solely from the shell baseline. 壳 **不得** 提供「peek 点按直接宿主业务」的配置旁路；各 feature 获得半圆点出全圆的行为 **必须** 仅来自壳基线，**不得** 自写半圆点击展开逻辑。

#### Scenario: 无 peek 直达业务旁路

- **WHEN** 宿主仅挂载壳并提供 `onInteractiveTap` / 可选拉满业务回调
- **THEN** 在 edge peek 上点按 MUST NOT 触发上述业务回调
- **AND** 宿主 MUST NOT 需要为「点缩进半圆」编写独立手势分支
