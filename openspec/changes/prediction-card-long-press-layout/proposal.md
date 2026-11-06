## Why

预测页列表/瀑布切换目前只靠标题栏图标，发现成本高。用户希望在竖屏直接长按卡片切换：瀑布里的预测卡切到纵向准确率列表，准确率卡切回瀑布，形成与卡形态对应的手势捷径。

## What Changes

- 竖屏非骨架事件卡：**整卡长按**切换 `PredictionCardsLayout`（grid→list，list→grid），走既有 `predictionCardsLayoutProvider` 持久化与 usage 上报。
- **骨架 demo 卡 MUST NOT** 因长按切换布局（也不借长按打开登录/绑定闸）。
- **横屏**强制瀑布时 MUST NOT 用长按改竖屏布局偏好（或忽略长按）。
- 标题栏列表/瀑布切换图标 **保留**。
- 短按卡既有行为（加事件等）不变；图区点柱小结仍短按优先，长按由整卡 InkWell 承接（与现 Material 长按竞争规则一致即可）。
- **非目标**：第三种布局；改横屏列数；改准确率计分。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：新增竖屏整卡长按切换 list/grid；骨架卡排除；标题栏切换仍有效。

## Impact

- Flutter：`smart_prediction_screen.dart`（`_PredictionEventCard` / 列表与网格 builder 传入长按回调）。
- 复用 `predictionCardsLayoutProvider`、`ClientUsageEvents.predictionLayoutToList/ToGrid`。
- 无新 HTTP；无原生；无新 test 文件。
