## ADDED Requirements

### Requirement: Portrait prediction voice entry MUST use EdgeDockShell

On the smart prediction page in **portrait** orientation, when landscape-voice (prediction voice) UI is shown, the client MUST present the listen affordance inside the shared `EdgeDockShell` (or equivalent wrapper that uses that shell), supporting edge peek (semicircle), edge engaged (full circle), and floating placements with drag-to-snap. The client MUST NOT keep a permanently fixed non-dockable chip as the only portrait listen control. **Landscape** prediction MUST keep a fixed listen chip and MUST NOT wrap that chip in `EdgeDockShell` in this change.

智能预测页**竖屏**展示预测语音入口时，客户端 **必须** 用共享 `EdgeDockShell`（或等价包装）呈现监听入口，支持贴边半圆 peek、贴边全圆 engaged、浮空 floating 及拖动吸附。**不得** 仅保留不可贴边收起的固定 chip 作为竖屏唯一入口。**横屏** **必须** 继续使用固定监听 chip，本变更 **不得** 为其包 `EdgeDockShell`。

#### Scenario: 竖屏为贴边球

- **WHEN** 用户在智能预测页竖屏且语音入口可见
- **THEN** UI MUST 展示可拖动的 EdgeDockShell 语音球（非仅固定 Positioned 胶囊）

#### Scenario: 横屏仍固定 chip

- **WHEN** 用户在智能预测页横屏且语音入口可见
- **THEN** UI MUST 展示固定位置的监听 chip
- **AND** MUST NOT 使用 EdgeDockShell 包裹该横屏 chip

### Requirement: Peek tap MUST only engage; peek MUST omit long caption

While the portrait voice dock is in edge peek, a tap MUST transition only to edge engaged and MUST NOT invoke listen/permission business (`onListenChipTap` or equivalent). The long `statusCaption` (or equivalent status string) MUST NOT be shown in peek. In edge engaged or floating, a tap MUST invoke the existing listen-chip business callback, and the client MAY show a short status caption beside or below the ball (MUST truncate with ellipsis if long).

竖屏语音球处于 edge peek 时，点按 **必须** 仅进入 engaged，**不得** 调用听/权限业务；peek **不得** 展示长状态文案。engaged 或 floating 时点按 **必须** 调用既有监听业务回调，并 **可** 在球旁或球下短显状态文案（过长 **必须** 省略号截断）。

#### Scenario: 半圆点按只展开

- **WHEN** 竖屏语音球为 edge peek 且用户点按热区（未拖过 slop）
- **THEN** 壳 MUST 进入 edge engaged
- **AND** MUST NOT 调用 `onListenChipTap`（或等价）

#### Scenario: 半圆无长文案

- **WHEN** 竖屏语音球为 edge peek
- **THEN** UI MUST NOT 展示完整/长 `statusCaption`

#### Scenario: 全圆或浮空点按进业务

- **WHEN** 竖屏语音球为 edge engaged 或 floating
- **AND** 用户点按热区（未拖过 slop）
- **THEN** 客户端 MUST 调用既有监听 chip 业务回调

### Requirement: Portrait voice dock position MUST persist via HomeInputDockStore semantics

The client MUST persist the portrait voice dock edge/along or floating center using the former home-input dock store API (`HomeInputDockStore` or renamed equivalent). When no valid prediction-voice placement is stored, the default MUST be left-edge peek near the bottom (left-lower). Previously persisted feeding-mode-dock placements MUST NOT be used as the prediction ball’s first-run default (key bump or ignore legacy keys).

客户端 **必须** 用原首页输入 dock 存储 API（`HomeInputDockStore` 或更名等价物）持久化竖屏语音球贴边或浮空位置。无有效预测球存档时，默认 **必须** 为左缘偏下 peek。历史喂养模式球存档 **不得** 作为预测球首次默认（bump key 或忽略旧 key）。

#### Scenario: 无存档默认左下

- **WHEN** 用户首次（或 key bump 后）进入竖屏预测且本地无有效预测球位置
- **THEN** 语音球 MUST 以左缘、沿边偏下的 edge peek 展示

#### Scenario: 拖动后冷启恢复

- **WHEN** 用户将竖屏语音球拖到某边并松手吸附（或浮空落点）后冷启动再进竖屏预测
- **THEN** 球 MUST 恢复为上次持久化的 edge/along 或 floating 中心

### Requirement: Portrait voice subtitle toast MUST be independent of the dock

When a portrait prediction voice subtitle is shown, its on-screen placement MUST NOT be computed solely to clear a fixed bottom-left chip next to the dock; the toast MUST use an independent layout (e.g. bottom-centered) that does not track the dock’s drag position as a sibling offset.

竖屏预测语音字幕展示时，其位置 **不得** 仅为避开固定左下 chip 而与球绑定；toast **必须** 使用独立布局（如底中），**不得** 随球拖动坐标作为唯一避让依据。

#### Scenario: 字幕不跟球走

- **WHEN** 竖屏语音球已被拖到右缘且字幕非空
- **THEN** 字幕 toast MUST 仍按独立规则布局（不得要求始终贴在球旁）

### Requirement: Portrait voice dock pointer MUST block home PageView swipe

While a pointer is down within the portrait prediction voice `EdgeDockShell` hittable target (including drag reposition and peek/engaged tap), the client MUST prevent the home PageView from horizontal page changes until the pointer is released or cancelled.

竖屏预测语音球 `EdgeDockShell` 热区内指针按下期间（含拖动 reposition 与 peek/engaged 点按），客户端 **必须** 禁止主页 PageView 横滑，直至抬起或取消。

#### Scenario: 拖动球横滑不切页

- **WHEN** 用户在竖屏语音球热区内按下并横向拖动
- **THEN** 主页 PageView MUST NOT 切换页面

#### Scenario: 抬起后恢复横滑

- **WHEN** 用户在球热区内操作后松开或取消
- **THEN** PageView 横滑 MUST 恢复可用

### Requirement: Portrait voice dock drag MUST reposition from any shell state

While the user is dragging the portrait voice dock for reposition (pointer movement exceeds tap slop until release), the client MUST snap to the new edge/along or floating center via `_finishDrag` (or equivalent), regardless of whether the shell was in edge peek or edge engaged when the drag started or ended. The client MUST NOT discard the drag and revert to the pre-drag placement solely because `_engaged` was true at pointer up.

竖屏语音球 reposition 拖动（超过 slop 至松开）期间，客户端 **必须** 无论壳处于 peek 或 engaged，均在松手时吸附到新 edge/along 或浮空落点；**不得** 仅因松手时 `_engaged` 为 true 而丢弃拖动并回到拖动前位置。

#### Scenario: 全圆 engaged 拖动仍落新位

- **WHEN** 竖屏语音球为 edge engaged（全圆）且用户拖动超过 slop 后松手
- **THEN** 球 MUST 吸附至拖动落点对应的新 edge/along 或 floating
- **AND** MUST NOT 回到拖动前的 edge/along

#### Scenario: peek 拉满 engage 后拖动松手仍落新位

- **WHEN** 用户自 peek 向内拉满进入 engaged 后继续拖动并松手
- **THEN** 球 MUST 仍按拖动落点吸附落位
