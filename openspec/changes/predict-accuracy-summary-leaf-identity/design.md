## Context

准确率样本来自根桶历史（`groupHistoryByRootEvent`），`PredictAccuracySample` 无叶子 id。非合并根预测按子分别算，但小结无法区分 AD/3D。产品定：非合并小结跟叶子；**合并根小结不跟叶子**。

基线：`predict-list-accuracy-bars`、`predict-merge-dimension`（v2.2.1）。

## Goals / Non-Goals

**Goals:**

- 非合并：小结行带叶子 logo + 名（子 accent）。
- 合并：小结不展示叶子身份。
- 样本保留 `leafEventId` 供非合并渲染。

**Non-Goals:**

- 不改柱高算法；不拆双子准确率卡；不改卡头跟根的对照 chrome。

## Decisions

1. **样本字段**：`predictAccuracySampleFromRecord` 写入 `leafEventId`（`historyRecordEventId`）；示例样本可用根 id 或空。  
2. **分支**：卡根 `mergePredict==true` → 小结纯文案行；否则有叶子定义时渲染 logo+名+明细。  
3. **颜色**：子名用 `resolveFeatureColor`/事件品牌色；准偏 traffic 色仍可用在明细或左侧指示，避免与子名色打架（推荐：名用子 accent，明细用 traffic）。  
4. **合并根**：即使历史挂在叶子，UI **故意**不展示叶子——与「合并预测无子身份」一致。

## Risks / Trade-offs

- [合并根用户想看奶种] → 产品明确不要；若以后要，另开增量。  
- [窄卡放不下 logo+名+明细] → 名可 ellipsis；logo 小尺寸（~14–16）。

## Open Questions

- （已定）合并根小结不跟叶子。
