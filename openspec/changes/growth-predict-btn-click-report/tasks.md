## 1. 点击上报

- [ ] 1.1 在 `ClientUsageEvents` 增加 `growth_predict_btn_click`（点击轨迹预测）与 `growth_predict_restart_click`（点击重新预测）；未开通用同一开始 id，description 标明未开通
- [ ] 1.2 已开通点击「轨迹预测」「重新预测」时，在 `_onPredict` 开头异步上报，不等 `startPredict` 结果
- [ ] 1.3 未开通点击「轨迹预测」打开开通窗时异步上报开始事件；喂养「AI智能分析」不上报这两条

## 2. 验收

- [ ] 2.1 对照规格：开始、未开通、重新预测三条路径的 featureId 与 description 正确，失败不 toast、不挡住预测或开通窗
- [ ] 2.2 无 `app/android/**` 变更；未新增裸 `debugPrint` / `print`；上报仍走 `AppDebugLog.clientUsage`
