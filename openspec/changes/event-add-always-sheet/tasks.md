## 1. 加事件收口

- [x] 1.1 `_onEventButtonTap`：`add` 下 `time`/`one` 与 `number` 同构开统一 sheet；去掉即时 now/开计时；保留 `time` 计时中 toast
- [x] 1.2 删除或闲置 `preferRecordSheet` / `confirmDirectLeafBeforeAdd` 对 sheet 的门闩（调用方可不再传）

## 2. 调用方清理

- [x] 2.1 `smart_prediction_screen`：去掉仅服务于确认/直点 sheet 的多余参数（若已无行为依赖）
- [x] 2.2 确认 `home_screen` 经共享路径自动获得 sheet，无需旁路即时 add

## 3. 验收

- [x] 3.1 喂养 / 多级 / 预测：`time` 与 `one` 均先 sheet；预测无「确认添加」；取消不落库
