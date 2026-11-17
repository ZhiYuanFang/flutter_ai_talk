## Why

竖列表准确率空态目前「每张零样本卡都出示例柱」。一旦某张卡已有真对照，其余卡仍铺满示例会造成「到处都是假数据」的噪音，削弱真准确率的可信感。产品改为：页面上**只要有一张卡**已能出真准确率，其它零样本卡改走空态占位，不再出示例。

## What Changes

- **BREAKING（相对现行 SHALL）**：取消「每一张零样本竖卡 MUST 都展示示例」的全局教学策略。
- 当当前竖列表中**至少一张**对照卡近窗内有 ≥1 条合格真样本时：其余零样本卡 MUST 渲染空态占位（不得示例柱 / 示例小结）。
- 当竖列表中**没有任何**卡有合格真样本时：零样本卡仍可按现有规则展示示例柱（保留冷启动教学）。
- 有真样本的卡：行为不变（只出真柱；点柱真小结）。
- **不改**：柱高算法、合并/非合并小结叶子身份、卡头跟根、营养品 expect 打戳问题（另案）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-list-accuracy-bars`：示例柱从「每卡独立空态」改为「页级真样本门闩 + 空态占位」。

## Impact

- Flutter：`smart_prediction_screen.dart`（竖列表建卡 / `_PredictAccuracyChartPane`）需页级 `anyRealAccuracy`（或等价）下传。
- 无 Go / 原生；Release N/A。
