## Why

喂养主页「今日汇总」固定挂在身份头与历史之间，只能看当天总额，滚动到昨天/更早时汇总脱节；跨午夜计时（如睡眠）按 `historyHomeDisplayInstant`（已结束 `eventNumber==0` 用 end）分日会把整段归到结束日。需要把汇总嵌进按日吸顶，并让日键与 Sheet 详图跟「开始日」对齐。

## What Changes

- **移除**喂养页身份头与历史列表之间的独立「今日汇总」面板（`HomeTodaySummaryPanel` 挂载位）。
- 每个历史**日期分块吸顶行**在日期文案之外，展示**该自然日**按 `eventId` 聚合的汇总 chip（logo + 品牌色）；无有效总额时吸顶**仅日期**、不占 chip 高度。
- 吸顶高度随该日 chip 折行**可变**（不再固定单行日期高）。
- 点击某日某事件 chip **必须**打开玻璃态 Sheet，内嵌复用 `TrendDayDetailChart`（**单日**；计次→时间线，计时→时长折线）；**不得**打开今昨双日小时趋势 Sheet。
- 打开上述当日汇总图时，客户端 **必须**经既有 `clientUsageReporter` **异步**（fire-and-forget）上报一条 client-usage 统计日志；上报 **不得**阻塞 Sheet 打开，失败静默（对齐 `client-usage-report`）。
- Sheet / 按日汇总数据 **必须**来自主页已加载的本地历史快照（含既有分页合并结果），**不得**为本能力新增专用日汇总/日详图 HTTP。
- 主页历史**日分块键** MUST 以记录 **`startTime`**（缺失时既有回退）所在本地自然日为准；本变更 **不得** 改动预测算法所用的时刻/分桶语义。
- chip 视觉仍按 `eventId` 对齐全局事件目录（logo / 品牌色），与既有品牌展示一致。

## Capabilities

### New Capabilities

- `home-per-day-summary-sticky`：按日吸顶汇总 chip、可变高度、空日仅日期、chip→单日 `TrendDayDetailChart` Sheet、打开 Sheet 时异步 usage 上报、本地快照聚合。

### Modified Capabilities

- `event-branded-ui`：废除「今日汇总展示」中「身份头与历史之间独立今日区」挂载与占位约束；品牌 chip 语义迁到按日吸顶。
- `home-history-date-sections`：吸顶行可含按日汇总；日分块键改为 `startTime` 本地自然日（仅主页历史分组）。
- `home-today-event-hourly-trend-sheet`：原「喂养今日 chip MUST NOT 打开小时趋势 Sheet」改为：按日汇总 chip MUST NOT 打开今昨小时 Sheet，且 MUST 打开单日 `TrendDayDetailChart` Sheet（细则在新能力）。
- `client-usage-report`：新增「点击按日汇总 chip 查看当日汇总图」稳定 `featureId` 与异步上报约束。

## Impact

- UI：`home_screen.dart`（卸今日汇总）、`home_history_scroll.dart` / `home_history_date_header.dart`（吸顶扩容）、新建/改造按日汇总与 Sheet 入口；复用 `trend_day_detail_chart.dart`、`home_today_summary_panel` chip 视觉或内联等价。
- 数据：`home_history_list_entries.dart` / `history_line_format.dart`（日键用 start；`historyHomeDisplayInstant` 行时刻展示 MAY 保留，但分组键不得再用 finished-end）；`aggregateTodayTotals` 泛化为按日聚合。
- 统计：`client_usage_events.dart` 新增事件常量；chip→Sheet 路径 `unawaited(reportEvent(...))`（或等价 fire-and-forget）。
- 分页：继续 `home-history-pagination`；更旧日的汇总随 `loadMore` 本地合并出现，无新 API。
- 预测 / Live Activity / 趋势中心 piece 分桶：本变更范围外，MUST NOT 误改。
- 基线对照：`openspec/specs/v2.1.4.md` 中 `event-branded-ui`、`home-history-date-sections`、`home-today-event-hourly-trend-sheet`、`client-usage-report`。
