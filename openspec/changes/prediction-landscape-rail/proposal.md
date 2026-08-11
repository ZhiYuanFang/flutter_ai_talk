## Why

智能预测页横屏仍沿用竖屏「顶栏横排身份 + 双列瀑布」，宽屏空间浪费且身份与卡片争高。需要横屏专用分栏：左栏竖排身份、右栏更密的瀑布，并收起与横屏无关的 chrome。

## What Changes

- 当 `Orientation.landscape`：预测页改为左身份栏 + 右事件瀑布。
- 左栏仅竖排展示宝宝昵称与月龄（无月龄时仅昵称）；**不**展示头像、调色盘、布局切换。
- 横屏隐藏「值得留意」、滑动引导大卡、「接下来3小时」；只保留左身份 + 右网格。
- 右栏强制 compact 瀑布；列数：竖屏 2、手机横屏 3、平板横屏（`shortestSide >= 600`）**5**；横屏禁用切到纵向列表（不显示切换入口，即便本地偏好为 list 也按瀑布渲染）。
- 竖屏布局与行为保持不变（含双列瀑布、顶栏工具、留意/引导/3小时等既有逻辑）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：增加横屏分栏布局、3 列瀑布、强制 compact、隐藏身份外 chrome/工具的要求。

## Impact

- 代码：主要 `smart_prediction_screen.dart`（含 `_WaterfallCards` 列数参数化、横屏分支）。
- 规格：增量修改 `smart-prediction-page`；不改后端 API。
- 测试：不新建 `**/test/**`；手工横/竖屏切换冒烟。
