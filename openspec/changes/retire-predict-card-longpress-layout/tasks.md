## 1. 去掉长按切布局

- [x] 1.1 `smart_prediction_screen`：竖屏热态不再构造 `onLongPressLayoutToggle`；卡上 `onLongPress` 不切布局
- [x] 1.2 准确率图区 / `_PredictAccuracyChartPane`：去掉 layout 长按回调接线
- [x] 1.3 确认标题栏 list↔grid 切换、持久化与 usage 上报仍可用

## 2. 验收

- [x] 2.1 竖屏瀑布长按卡：不进列表/准确率（代码侧：无 layout 长按）
- [x] 2.2 竖屏列表长按卡或柱图：不回瀑布（代码侧：图区无 layout 长按）
- [x] 2.3 点标题栏图标：仍可切 list/grid（AppBar IconButton 保留）
