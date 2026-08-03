## Why

`EdgeDockShell` 与 tip 接线仍允许「半圆点按直接做宿主业务」（`externalPeekEngage`），宿主还要各自写「点缩进球」逻辑，和「对齐模式球、半圆点只露出全圆」的产品冻结冲突。需要把 **点按只 engage、拉满才可自动业务** 收成通用基线，宿主只挂全圆/浮空上的业务回调。

## What Changes

- **收紧壳基线**：edge peek 上的点按 **必须** 仅进入 engaged（全圆露出），**不得** 调用宿主业务回调。
- **拉满路径**：累计向内拉过阈值时，壳 **必须** 先 engage；若宿主提供拉满业务回调则 **可** 自动触发业务（如 tip 展开），未提供则停留在 engaged。
- **移除旁路**：删除或废弃 `externalPeekEngage` / peek 上直接 `onPeekEngage` 展开；宿主 **不得** 再为「点半圆」写专用展开逻辑。
- **tip 对齐**：半圆点 → 全圆；全圆/浮空点 → 展开卡；拉满 → 可自动展开（同一业务回调）。
- **模式球**：继续走基线（点半圆 engage；业务仅在全圆/浮空 `onInteractiveTap`）；拉满默认不自动切模式。

## Capabilities

### New Capabilities

-（无；复用并收紧 `extract-edge-dock-shell` 引入中的壳/tip 能力。）

### Modified Capabilities

- `edge-dock-shell`：明确 peek 点按仅 engage；拉满 engage + 可选自动业务；禁止 peek 点按直达宿主业务。
- `home-tip-edge-dock`：改写「点 peek → expanded」为两步；拉满可自动 expanded；宿主不写半圆点击专用逻辑。

## Impact

- 代码：`app/lib/ui/widgets/edge_dock_shell.dart`、`home_tip_panel.dart`；模式球 `home_input_mode_dock.dart` 预期零行为回归或仅去掉未用旁路。
- 依赖：建立在 `extract-edge-dock-shell` 已落地的壳之上（同仓未归档 change 上增量）。
- 基线对照：`openspec/specs/v2.0.3.md` 输入模式贴边 dock（半圆 → 全圆再业务）精神一致；不改 PageView / Android 原生。
