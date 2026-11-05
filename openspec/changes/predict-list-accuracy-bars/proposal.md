## Why

预测页纵向列表卡内仍是「近 7 日趋势折线」，看不出各自然日预报准不准；此前误把准确率叠在趋势中心量柱上，表面错误且与产品意图不符。history `expect*` 打戳已可用，应在**预测竖列表卡**用准确率柱表达近 7 日命中情况，并支持点柱后在**同一卡图区**切到当日预测小结。

## What Changes

- **预测页纵向列表**（非趋势中心、非横滑/瀑布）：卡内图区用近 7 日**准确率柱图**替换 `_LookbackChart` 折线；柱高 = 当日准确率 0–100%；柱顶展示整数 `%`。
- **无合格样本日**：不画柱、不标 `%`（空白槽位，不伪造 0%）。
- **点击某日有样本的柱**：卡内图区**整块替换**为该日「预测小结」——该事件当日每次发生的 expect 与实际对照列表（非跳转新页、非 bottom sheet）。
- **退出小结**：卡内提供明确返回（如「近7日」），回到准确率柱图。
- **计分**：复用 `expectStartTime` + `|actual−expect| ≤ 30 分钟` 命中；仅含已存 `expect*` 的行；**禁止**对老行重放伪造 expect。
- **回滚误改**：去掉趋势中心 `TrendNDayBarChart` 上的准确率顶标与「预测小结」入口（若有）；趋势量柱恢复为仅反映总量。
- **非目标**：不改横滑卡 / 瀑布布局；不计 duration/amount；不改 Go API；不做 UCG 隐藏。

## Capabilities

### New Capabilities

- `predict-list-accuracy-bars`：预测竖列表卡内近 7 日准确率柱、柱顶 `%`、点柱卡内替换为当日预测小结。

### Modified Capabilities

- （无基线 capability 改写；`trends-n-day-predict-accuracy` 变更作废/由本变更回滚其 UI 落地。）

## Impact

- Flutter：`smart_prediction_screen.dart`（纵向卡图区）；可复用/上移 `trend_predict_accuracy.dart` 纯函数；回滚 `trend_n_day_bar_chart.dart` / `trends_screen.dart` 准确率叠加。
- 依赖：`history-expect-fields-flutter`（及 Go twin）已落库透传。
- 无新 HTTP；无 Android/iOS 原生。
- 关联：`openspec/changes/trends-n-day-predict-accuracy` **superseded**，勿再 apply；其已改代码由本变更任务回滚。
