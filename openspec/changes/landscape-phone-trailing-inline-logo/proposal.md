## Why

手机横屏预测瀑布流每张卡都用「倒计时上方大 logo」，下方行卡片过高、一屏事件偏少。产品要求：仅手机横屏下，**视觉第一行**维持现状大 logo，**第二行及以后**改为事件名称左侧小 logo 以降低高度；平板横屏暂不改动。（曾误写为「第一列/后列」，已更正为「第一行/后续行」。）

## What Changes

- 手机横屏（`shortestSide < 600` 且 landscape）瀑布流：每列中 **行索引为 0**（该列顶部、共同构成视觉第一行）的普通卡保持居中大 logo；**行索引 ≥ 1** 的普通卡将 logo 置于事件名称左侧，并省略倒计时上方大 logo。
- 等价判定：全局 `index < columnCount` 为大 logo，其后为侧 logo（与 `i % columnCount` 分列一致）。
- 平板横屏（`shortestSide >= 600`）与竖屏网格：**不**引入按行差异。
- 计时中卡若已是标题旁 logo：保持即可。
- 心跳 soonest：跟当前可见 logo（大图或侧 logo）。

## Capabilities

### New Capabilities

- `landscape-phone-waterfall-logo`：手机横屏瀑布流按**行**的事件 logo 布局（首行大图 / 后续行标题旁）。

### Modified Capabilities

- （无）基线 `v2.1.0` 未收录该细则；列数规则仍以进行中的 landscape rail 等为准。

## Impact

- `app/lib/ui/smart_prediction_screen.dart`（`_WaterfallCards` 传列内行索引或全局 index、`_PredictionEventCard`）。
- 飞入锚点挂在当前可见 logo。
- **实现注意**：若代码仍按 `columnIndex > 0` 分支，须改为按行（`rowIndexInColumn > 0`）。
