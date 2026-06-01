## Why

主页「今日」事件总结区的 chip 目前仅展示各事件当日累计，无法快速对比**同一事件在一天内的小时分布**，也无法与昨日对照。用户需要在点击 chip 后，以玻璃态底部 Sheet 查看今/昨双折线趋势，且数据应先本地即时展示、再由 API 校正完整历史。

## What Changes

- `HomeTodaySummaryPanel` 中事件 chip **可点击**，打开玻璃态底部 Sheet。
- Sheet 内展示该事件 **今日 + 昨日** 两条折线（仅折线，无柱图）；横轴固定本地自然日 **0:00–24:00**（24 个整点桶）；纵轴上限为今/昨两日该事件各桶值的最大值。
- **竖屏**：横轴均匀展示 **5** 个时间文案；纵轴 **3** 个刻度。**横屏**：横轴 **7** 个时间文案；纵轴 **5** 个刻度。
- 数据策略：**先本地**（`homeHistoryProvider` 已加载记录）聚合渲染，**后 API**（`GET /device/history/api/piece` 昨日 0:00 至今日 23:59:59）刷新。
- **未结束计时**（`eventNumber==0` 且 `endTime` 未设置）**不计入**曲线与 chip 总额规则一致。
- **无记录时**仍绘制 **y=0** 的 24 点平线，不显示「暂无数据」空态替代图表。
- 视觉复用 `HistoryEditGlassPanel` 与固定浅色前景，与历史编辑 Sheet 一致。
- **后端 MVP**：复用现有 `piece` 接口，**不强制**修改 `go_ai_talk`；设计文档记录可选预聚合端点。

## Capabilities

### New Capabilities

- `home-today-event-hourly-trend-sheet`：今日 chip 点击、玻璃 Sheet、双折线图、方向自适应轴标签与图例。
- `history-hourly-dual-day-aggregation`：今/昨 24 整点桶本地聚合、piece API 双日映射、排除进行中计时、零线数据策略。

### Modified Capabilities

- （无）不修改趋势中心周/月/季行为；不修改今日 chip 累计公式（仅复用 `countsTowardTodayTotal`）。

## Impact

- **Flutter**：`home_today_summary_panel.dart`、新建 Sheet/图表组件、`trend_series_bucket.dart` 或新聚合模块、`remote_trends_repository.dart`（双日 piece 封装）、`home_screen.dart`（可选传 history）。
- **go_ai_talk**：MVP 无变更；可选后续 `piece/hourly` 预聚合。
- **依赖**：已有 `fl_chart`、`HistoryEditGlassPanel`。
