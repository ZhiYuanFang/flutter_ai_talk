## Why

智能预测页折线用于解释「即将发生」的 `nextAt` 时刻。当前今日点仍从已发生 occurrence 中按 TOD 最近选取，会把今天已经发生的记录画上去，削弱「预测锚点」语义。产品要求：仅当 `nextAt` 落在今天时，今日点必须画在 `nextAt` 上。

## What Changes

- 折线取点规则调整：本地日历 **今天** 的点，仅在 `nextAt` 与今天同自然日时绘制，且坐标为 `nextAt`（可晚于 `now`，含已逾期的同日 `nextAt`）。
- **今天** 不得再用「已发生 occurrence 中 TOD 最近」规则覆盖或替代该点。
- 若 `nextAt` 不在今天（明天及以后），今日列 **不画点**（即使今日已有 occurrence）。
- 昨天及更早（`[now-6d, yesterday]`）仍按每日一点、贴近 `nextAt` TOD 的 occurrence 规则不变；虚线连接不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：修改「近 7 日虚线折线」取点规则中关于「今天」的语义。

## Impact

- **Flutter**：`dailyPointsNearAnchorTod` / `buildSmartPredictionRows`；图表 Y 轴尺度须能容纳可能晚于 `now` 的今日 `nextAt`。
- **测试**：不新建 `**/test/**`；手工看今日点是否落在预测时刻。
- **Android**：不改原生，不强制 release APK。
