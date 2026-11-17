## Context

竖列表 `_PredictAccuracyChartPane` 按卡独立判断：该卡 `accuracyRecords` 近窗无合格样本 → 示例柱。基线要求「每张空卡都示例」。产品改为页级门闩：有任一张真样本后，其它零样本卡改空态占位。

基线：`predict-list-accuracy-bars`（v2.2.1）。叠在 `predict-accuracy-summary-leaf-identity` 之上（本变更不改小结叶子身份）。

## Goals / Non-Goals

**Goals:**

- 页级 `anyRealAccuracy`：当前竖列表参与对照的卡中，任一近窗有 ≥1 合格真样本即为真。
- `anyRealAccuracy==true` 且本卡零样本 → 空态占位（无示例柱/小结）。
- `anyRealAccuracy==false` → 零样本卡仍示例（冷启动教学）。

**Non-Goals:**

- 不修营养品/非合并 expect 打戳；不改柱算法；不改合并小结规则；瀑布/compact 无准确率图区不在范围。

## Decisions

1. **门闩范围**  
   与当前竖列表 `listRows` 中会渲染准确率图区的卡一致（开启推演且有 pred、非预约过滤后的对照卡）。关推演 / 无图区卡不计入「有真样本」，也不要求空态占位。

2. **合格真样本判定**  
   复用现有 `predictAccuracySamplesFromHistory`（或等价日 percent 非全 null）。与单卡 `hasAny` 同一规则，避免门闩与柱图不一致。

3. **下传方式**  
   在 `ListView` 建卡前一次扫描 `accuracyByRoot` → `bool pageHasRealAccuracy`，传入 `_PredictAccuracyChartPane`（或卡）。禁止每卡再全页重扫 history。

4. **空态占位**  
   居中短文案「暂无预测对照」（或既有等价文案）；保留图区标题「预测准确率分布图」（无「· 示例数据」）；**不得**可点示例小结。高度与图区一致，避免卡高跳动过大。

5. **示例小结**  
   仅当本卡仍走示例柱时可用；门闩空态下不存在示例柱入口。

## Risks / Trade-offs

- [一卡有真、它卡全空显得「秃」] → 产品要的；文案说明暂无对照。  
- [门闩与单卡 hasAny 算法漂移] → 共用同一采样函数。  
- [关推演后唯一真样本卡消失 → 其它卡突然变示例] → 可接受；跟当前可见竖列表即时重算。

## Open Questions

- （已定）全员仍无真样本时保留每卡示例；有任一张真样本后零样本改空态。
