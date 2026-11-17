## Why

预测页整卡（及准确率图区）长按会切换 list↔瀑布；list 态即准确率对照卡。用户常误触进入准确率面。产品要求**只去掉卡片长按切换**，保留标题栏布局图标，准确率列表能力本身不退役。

## What Changes

- 竖屏预测事件卡：**不得**再通过整卡 `onLongPress` 切换 `predictionCardsLayout`（list/grid）。
- 准确率柱/小结图区：**不得**再注册显式长按切布局。
- **保留**：AppBar/标题行布局切换图标、本地持久化、usage 上报；list 准确率柱与瀑布倒计时卡均仍可用。
- **不改**：横屏布局偏好语义、短按加记录/点柱小结等既有短按行为。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：取消「竖屏整卡长按切换 list/grid」；明确仅标题栏切换。
- `predict-list-accuracy-bars`：取消「准确率图区长按切换布局」。

## Impact

- Flutter：`smart_prediction_screen.dart`（去掉 `onLongPressLayoutToggle` / 图区长按接线）；可选清理死参数。
- 无 Android 原生；无 Go；Release N/A。
