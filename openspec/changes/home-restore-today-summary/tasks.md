## 1. 恢复面板

- [x] 1.1 恢复 `home_today_summary_panel.dart`（git 历史为底），确认 pill/logo/折叠行为与取色走现网 tokens/`AppColor`
- [x] 1.2 `HomeScreen`：用 `aggregateTodayTotals` 挂载今日汇总于身份头与历史之间；`onChipTap` 不接线 Sheet

## 2. 验收

- [x] 2.1 有今日数据时显示 chip；无数据不占位；点击 chip 不打开小时趋势 Sheet；右上趋势仍可用
