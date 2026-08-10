## 1. 预测页开关

- [x] 1.1 list/grid 卡片恢复紧凑推演开关（迷你 Switch）；接线 `forecastDisabledIdsProvider`
- [x] 1.2 `smartPredictionRowsProvider` / `homePredictionTipProvider` 重新消费 disabled 集合；OFF 置灰无图无相对时间

## 2. 留意与小组件

- [x] 2.1 `predictionCareAlertProvider` 过滤推演关闭的 eventId（不进跑马灯）
- [x] 2.2 `buildHomeWidgetPayload`（及 interactivity 重算）排除 disabled；`setEnabled` 后 `scheduleHomeWidgetSync`

## 3. 验收

- [x] 3.1 验证：网格/纵向均可关；关后 tip/留意/小组件均不含该事件；重启保持关闭
