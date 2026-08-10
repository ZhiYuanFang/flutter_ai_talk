## Why

智能预测页顶部小贴士卡占用首屏，并带有「小贴士」「点击进入陪伴」等多余 chrome。tip 应退到页面底部作轻量入口：横向展示文案，点进陪伴；文案不长时保持静止，避免无意义空转。

## What Changes

- **BREAKING（UI）**：移除预测页 tip **顶部卡片**；改为页面 **底部固定**条。
- 底栏仅展示 tip **正文**为 **横向跑马灯**；**不得**展示「小贴士」「点击进入陪伴」字样。
- 点击底栏任意可点区域 **必须** 进入陪伴聊天（既有 Clinic 激活 + `/companion`）。
- tip 文案 **短于可视宽度时静止**；仅当溢出时横向滚动。
- 无 tip 文案时 **整条底栏隐藏**。
- 值得留意跑马灯仍在 tip 原上方位置逻辑之后：标题 → 留意 → 卡片区 → **底栏 tip**（tip 不再插在标题与留意之间）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：tip 展示位置、形态与交互（底栏横向跑马灯 / 短文静止 / 点击进陪伴）。

## Impact

- UI：`app/lib/ui/smart_prediction_screen.dart`（挪移 tip、新横向跑马灯组件）。
- 数据：仍用 `widgetTipCardTextProvider`；不改 tip 拉取/SSE。
- 与留意竖向跑马灯、list/grid 卡片并存：底栏用 Column 底槽，避免遮挡卡片。
- 不自动新建测试文件。
