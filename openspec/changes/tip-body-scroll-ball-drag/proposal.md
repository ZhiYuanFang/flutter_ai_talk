## Why

展开 tip 上同时挂 pan + tap，且 Markdown 可选中，导致**点文案进陪伴经常不触发**；产品同时要求正文**可滚动阅读**、展开态**不可拖卡**，只有折叠成球后才能拖图标贴边——与「无滚动 + 整卡拖吸入」冲突，需单独收紧手势分层。

## What Changes

- **BREAKING（展开态）**：展开 tip **不得** 拖动卡片或顶标去贴边；拖动仅在折叠/贴边球（`EdgeDockShell`）上可用。
- 展开正文 **必须** 可竖向滚动展示文案（取消 tip 场景下「禁止 ScrollView」）。
- 展开态：正文轻点（仅 done + 可注入）进陪伴；顶标点按仍折叠成球；去掉展开态 `onPan*`。
- tip 正文关闭 Markdown 选择（或等价）以免抢走 tap；陪伴页 `ClinicAnswerBody` 行为可保持不变（参数化）。

## Capabilities

### New Capabilities

-（无）

### Modified Capabilities

- `home-tip-center-presentation`：正文允许滚动；去掉「不得用 ScrollView」。
- `home-tip-gesture-chrome`：展开态无拖卡；顶标仅折叠；拖只在球态。
- `home-tip-companion-bridge`：保证正文 tap 不被 pan/选区抢走（仅 done）。
- `home-tip-edge-dock`：贴边吸入仅从球拖达成；展开过半吸入路径取消。

## Impact

- 代码：`home_tip_panel.dart`；可选 `ClinicAnswerBody` 增加 scroll/selectable 开关。
- 覆盖/修正未归档的 tip-tap / edge-minimize 手势句。
- 不改 tip SSE、不改 Android 原生。
