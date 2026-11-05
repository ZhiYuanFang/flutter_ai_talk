## Why

~~趋势中心近 N 日总量柱图只反映「当天喂了多少」，看不出「那天预报准不准」。~~

**SUPERSEDED**：产品面应为**预测页纵向列表卡**准确率柱 + 卡内小结，而非趋势中心量柱叠标。后继变更见 `openspec/changes/predict-list-accuracy-bars`。本变更勿再 apply；已落地的趋势 UI 由后继变更回滚。

## What Changes

- （作废）原计划在趋势中心 `TrendNDayBarChart` 柱上叠准确率 `%`。
- 后继：`predict-list-accuracy-bars`。

## Capabilities

### New Capabilities

- （作废）`trends-predict-accuracy` — 由 `predict-list-accuracy-bars` 取代。

### Modified Capabilities

- （无）

## Impact

- 已改代码：`trend_predict_accuracy.dart`、`trend_n_day_bar_chart.dart`、`trends_screen.dart` — 由 `predict-list-accuracy-bars` 回滚 UI / 复用纯函数。
