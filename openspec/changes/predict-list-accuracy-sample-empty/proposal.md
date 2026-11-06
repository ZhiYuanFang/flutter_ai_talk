## Why

预测竖列表卡对照图区在近窗内无合格 `expectStart` 样本时只显示「暂无预测对照」，用户看不出「预计 vs 实际准不准」是什么意思。需要在**每张无样本卡**的图区用**示例数据**演示柱图与点柱细节，并明确标注示例，避免当成真实准确率。

## What Changes

- 竖列表（非 compact）卡图区：当该根近对照窗内**没有任何**合格准确率样本时，MUST 展示示例近 N 日准确率柱（故意有高有低），上方居中小字说明为示例数据；MUST NOT 仅显示「暂无预测对照」。
- 示例柱 MUST 支持与真数据同构的点柱交互：进入卡内「预计 → 实际」示例小结，并可返回柱图；小结与柱图顶栏 MUST 持续标明示例。
- 示例内容 MUST NOT 包含「下一次预测 / 上一次事件时间」文案或字段；卡上半倒计时与「上一次」行保持既有行为（对照图区外）。
- 有任一日真样本时 MUST 只画真数据，MUST NOT 与示例柱混用；示例 MUST NOT 写入 history、准确率统计或 pending。
- **不做**：改横滑/瀑布；改计分公式；整卡冷态 `prediction_demo_skeleton`；藏卡上半倒计时/上一次。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-list-accuracy-bars`：无合格样本时空态改为示例柱 + 标注 + 可点示例小结；明确示例不得含下次/上一次，且不得污染真统计。

## Impact

- Flutter：`smart_prediction_screen.dart` 中 `_PredictAccuracyChartPane`（及示例数据构造辅助）。
- 对照：`predict-list-accuracy-bars`；基线以该 change 规格为准。
- 无 Go / 原生 / 新 HTTP。
