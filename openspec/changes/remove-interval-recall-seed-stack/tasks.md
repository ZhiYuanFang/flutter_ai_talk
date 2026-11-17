## 1. 拆卡面与 Sheet 入口

- [x] 1.1 删除 `smart_prediction_screen` 中 `showIntervalRecall`、`_onPickIntervalRecall`、调间隔 `onAdjustInterval` 及「补充大概多久一次」UI
- [x] 1.2 删除 `prediction_recall_interval_picker.dart`（及仅被其引用的思考文案依赖）

## 2. 硬删种子栈与旁路

- [x] 2.1 删除 `prediction_recall_seed.dart`、`prediction_recall_seed_store.dart`、`prediction_recall_provider.dart`（及 shell/wipe 中种子清理改为 remove prefs key 或删除调用）
- [x] 2.2 从 `event_next_predictor` / `smart_prediction_rows` / `smart_prediction_provider` / `home_widget_sync` 等移除 `recallIntervalsByRoot` 与种子 merge/伪记录路径
- [x] 2.3 删除或掏空 `prediction_recall_onboarding_panel` 中写种子 /「大概多久一次」；无引用则删文件
- [x] 2.4 启动或 wipe 时 `remove('prediction_recall_seeds_v1')`；全仓搜确认无 `PredictionRecallSeed` / `补充大概多久` / `pickRecallInterval` 残留

## 3. 校验

- [x] 3.1 热态有 lastAt 无亲和预测：无间隔钮，见进度或其它非种子空态；「补充上一次」/预约「补充下次」仍可用
- [x] 3.2 `dart analyze` / IDE 无悬空引用；`openspec validate remove-interval-recall-seed-stack --strict`
