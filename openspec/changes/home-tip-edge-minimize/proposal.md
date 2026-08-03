## Why

居中小贴士挡住视线时只能「关闭」丢掉内容；产品需要像输入模式球一样**拖到四边最小化**为胖宝圆标并可再展开，同时补齐按钮实色底、顶部品牌圆标，并去掉卡内滚动（服务端限长）。

## What Changes

- **BREAKING（相对 `home-tip-center-card` 呈现）**：展开态 tip **可拖动**；当贴边越过 tip **一半宽/高**时，morph 为胖宝平拍圆并**吸入该边**（四边均可），视觉手感对齐输入模式 dock 半圆贴边。
- 吸入 = **最小化（docked）**，保留 tip 内容与流状态；点圆或拖出可**再展开**。点「关闭」仍为 dismiss → idle。
- **docked 时再来新 tip**（`startStreaming` / presentationGeneration 递增）：**强制**退出 docked，弹回**居中**并再播弹性展开。
- 卡片**顶部居中**展示胖宝平拍圆图（`app_icon_round.png` / `kStartupIconAsset`）；docked 圆标同一资产。
- 「关闭」「对话」默认态须有**不透明背景色**（不得透明描边底）。
- 卡内**取消滚动**；假定服务端限长不溢出组件高度（客户端可不滚动；超长时 MAY clip，不以 ScrollView 为主路径）。
- 沿边吸附时尽量与 `HomeInputModeDock` **错开 along**，避免完全重叠。

## Capabilities

### New Capabilities

- `home-tip-edge-dock`：拖动、四边最小化/展开、过半阈值、与输入 dock 避让、docked 遇新 tip 强制居中再弹。

### Modified Capabilities

- `home-tip-center-presentation`：顶标圆图、按钮实色、去卡内滚动；展开态布局与拖动壳衔接。

## Impact

- 代码：`home_tip_panel.dart`（拖动/形态状态机）、可能抽 tip 贴边几何（可参考 `home_input_dock_geometry`）、`home_screen` 挂载层、`tip_provider`/`tip_models`（可选 `uiMode: expanded|docked` 或纯 UI 状态 + listen generation）。
- 依赖进行中变更：`home-tip-center-card`（居中卡、shouldShow、generation、关闭/对话入口）。
- 无 Android 原生；无新 Debug tag 预期。
