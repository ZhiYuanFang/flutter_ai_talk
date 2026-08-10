## Why

喂养主页顶部预测「跳过」与「今日总结」chip 区增加噪音、挤占历史列表空间；预测升降级已由智能预测页与小组件承接，主页只需轻量贴士入口。

## What Changes

- **BREAKING（主页）**：去掉顶部预测贴士上的「跳过」按钮与主页侧 skip 写入路径；贴士条保留，点击仍进入智能预测页。
- tip 选条 **仍可** 过滤小组件 hero-skip / 推演关闭（与现 `homePredictionTipProvider` 一致）；仅移除主页触发 skip 的 UI。
- **BREAKING（主页）**：移除 `HomeTodaySummaryPanel`（今日汇总 chip）；不再从主页 chip 打开今昨小时趋势 Sheet。
- 趋势中心（标题栏入口）与 Sheet 实现本身可保留，只是失去主页 chip 入口。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-prediction-tip-bar`：废止顶栏「跳过」；保留贴士展示与点进预测页。
- `event-branded-ui`：废止「今日汇总展示」在主页的强制呈现。
- `home-today-event-hourly-trend-sheet`：废止「今日总结 chip 打开 Sheet」入口（面板移除后无 chip）。

## Impact

- UI：`home_prediction_tip_bar.dart`、`home_screen.dart`；可删或停用 `home_today_summary_panel.dart` 挂载与仅服务它的 `todayTotals` 计算。
- 不改智能预测页、小组件 skip 存储本身、服务端 API；不自动新建测试文件。
- 对照基线 `openspec/specs/v2.1.0.md` 中今日汇总 / 今日趋势 Sheet 相关 Requirement，以及未归档 `home-prediction-tip-bar` delta。
