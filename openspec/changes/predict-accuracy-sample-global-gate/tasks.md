## 1. 页级门闩

- [x] 1.1 竖列表建卡前扫描各对照卡 `accuracyRecords`，用现有采样规则算 `pageHasRealAccuracy`
- [x] 1.2 将该 bool 传入 `_PredictAccuracyChartPane`（或卡）

## 2. 图区分支

- [x] 2.1 本卡零样本 + `pageHasRealAccuracy==false`：保持示例柱 / 示例小结
- [x] 2.2 本卡零样本 + `pageHasRealAccuracy==true`：空态占位「暂无预测对照」；无示例柱/小结；点击不进加事件
- [x] 2.3 本卡有真样本：仍只出真柱（不变）

## 3. 验收

- [x] 3.1 全员零样本：各卡仍见「· 示例数据」柱
- [x] 3.2 仅一张有真样本：该卡真柱；其它零样本卡为空态占位（无示例）
- [x] 3.3 热重载 / 列表变化后门闩即时跟随
