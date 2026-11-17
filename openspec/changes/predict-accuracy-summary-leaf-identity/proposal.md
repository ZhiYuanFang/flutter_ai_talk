## Why

竖列表准确率按根聚合历史，但当日小结行只有「预计→实际」文案、无子事件身份。非合并根（如营养品 AD/3D）用户看不到某条对照属于哪个子。需在小结中标出子 logo 与子名（子色），同时合并根小结保持根语义、**不**跟叶子。

## What Changes

- `PredictAccuracySample`（或等价）携带发生叶子 `eventId`（来自历史行）。
- **非合并根**（`mergePredict=false` 且有子）：当日小结每一行 MUST 展示对应子事件 logo、子事件名；事件名颜色 MUST 跟该子品牌色；预计→实际行保留。
- **合并根**（`mergePredict=true`）：小结行 MUST NOT 展示叶子 logo/名（不跟叶子）；保持现有预计→实际样式（可用根色或准偏 traffic 色，不引入子身份）。
- 无子的根事件：小结行无需加叶子身份（与今类似）。
- **不改**：柱图仍按根日聚合；对照卡头 logo/名/色仍跟根；瀑布热态胜出子规则不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-list-accuracy-bars`：小结行按合并/非合并区分叶子身份展示。
- `predict-merge-dimension`：明确合并根准确率小结不展示子身份（与非合并对照）。

## Impact

- Flutter：`trend_predict_accuracy.dart`、`smart_prediction_screen.dart` 小结 UI；catalog `mergePredict` 判定。
- 无 Go / 原生；Release N/A。
