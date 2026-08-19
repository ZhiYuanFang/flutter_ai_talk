# Design: 横屏可调列数与卡片 scale

## 存储

- `PredictionLandscapeColumnStore`：`prediction_landscape_column_count_v1` → `int?`；无存档时 UI 层按设备档默认 3/5。
- `predictionLandscapeColumnProvider`：`AsyncNotifier<int?>`，± 时 clamp 1–7 并 save。

## 列数

```dart
effective = stored ?? (isTabletLandscape ? 5 : 3);
```

仅 `Orientation.landscape` 使用；竖屏仍 `waterfallColumns = 2`。

## Scale

`PredictionLandscapeCardMetrics.forGrid(gridWidth, columnCount, isTabletLandscape)`：

- 基准列数：手机 3、平板 5。
- `refCell = (gridWidth - (baseline-1)*gap) / baseline`
- `cell = (gridWidth - (n-1)*gap) / n`
- `scale = cell / refCell`（无 clamp）

基准 compact 尺寸 × scale：标题 14、相对 12、辅助 10、倒计时 26、titleLogo 28、heroLogo 52、switchScale 0.72、padding、列/行 gap。

## 左栏步进器

扩展 `_PredictionLandscapeIdentityRail`：月龄块下方 `[−] 数字 [+]`；`n==1` 禁减、`n==7` 禁增；未登录也展示。

## 接线

- 横屏 `buildCardsBody` 用 `LayoutBuilder` 算 metrics，传入 `_PredictionEventCard(landscapeMetrics: …)`。
- `_WaterfallCards` 可选 `columnGap`/`rowGap`（随 scale）。
