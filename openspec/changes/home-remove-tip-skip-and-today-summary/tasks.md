## 1. 顶栏预测

- [x] 1.1 移除 `HomePredictionTipBar`「跳过」按钮、`onSkip` / `_skipTip`；整条点击进智能预测
- [x] 1.2 确认 tip 选条仍可过滤推演关闭与小组件 skip（不改 provider 除非需删无效引用）

## 2. 今日总结

- [x] 2.1 `HomeScreen` 卸下 `HomeTodaySummaryPanel` 及 chip → 小时趋势 Sheet 接线
- [x] 2.2 清理仅服务今日总结的 `todayTotals` 等死代码；无引用则可删 `home_today_summary_panel.dart`

## 3. 验收

- [x] 3.1 喂养页：有 tip 时无「跳过」；点击 tip 进预测页
- [x] 3.2 喂养页：历史列表上方无今日汇总 chip
