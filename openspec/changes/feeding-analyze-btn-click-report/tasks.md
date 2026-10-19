## 1. 点击上报

- [x] 1.1 在 `ClientUsageEvents` 增加 `feeding_analyze_btn_click`，description 为「点击AI智能分析」
- [x] 1.2 在 `_onTapAnalyze` 开头异步上报该事件，不等 `refreshDailyManual` 结果；分析进行中再点也报
- [x] 1.3 未开通正文「点击开通智能分析」不上报；不得改报 `growth_predict_btn_click` 或 `growth_predict_restart_click`

## 2. 验收

- [x] 2.1 对照规格：发起分析的点击、进行中再点都会上报 `feeding_analyze_btn_click`；失败不 toast、不挡住分析
- [x] 2.2 无 `app/android/**` 变更；未新增裸 `debugPrint` / `print`；上报仍走 `AppDebugLog.clientUsage`
