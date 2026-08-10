## Why

喂养页卸下「今日总结」后，用户无法在历史列表上方一眼看到当日各事件汇总；身份顶栏已落地，需要把轻量今日 chip 区加回来。产品明确只要卡片展示，不恢复 chip 打开今昨小时趋势 Sheet。

## What Changes

- 恢复喂养页「今日」汇总面板（`HomeTodaySummaryPanel` 或等价）：按 `eventId` 聚合当日总额 chip，含 logo/品牌色、超过两行可折叠。
- 挂载位置：沉浸身份头下方、历史列表上方（贴士条仍保持现网注释/不强制恢复）。
- **不**接线 `showHomeEventHourlyTrendSheet`；chip **不得**因本变更成为打开今昨小时 Sheet 的入口（趋势仍走右上「趋势」等既有入口）。
- 无今日总额时保持不占位（`SizedBox.shrink` 或等价）。
- 对冲未归档的 `home-remove-tip-skip-and-today-summary` 中「移除今日总结」意图；**不**恢复贴士「跳过」按钮。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-branded-ui`：恢复主页「今日汇总展示」Requirement（展示向；不含 Sheet 入口）。
- `home-today-event-hourly-trend-sheet`：明确喂养今日 chip **不得**再作为打开今昨小时趋势 Sheet 的入口（与「只要卡片」一致；Sheet 实现可保留但不挂主页 chip）。

## Impact

- UI：恢复 `home_today_summary_panel.dart`（可从 git 找回并按需对齐 `AppColor`/tokens）；`home_screen.dart` 用 `aggregateTodayTotals` 挂载。
- 数据：复用既有 `TodayEventTotal` / `aggregateTodayTotals`；无新 API/原生。
- 关联：与 `home-remove-tip-skip-and-today-summary` 部分对冲；与 `home-header-baby-identity` 布局衔接。
