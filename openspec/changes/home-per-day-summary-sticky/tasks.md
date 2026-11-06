## 1. 日键与按日聚合

- [x] 1.1 `buildHomeHistoryDayGroups`（及排序日内列表若依赖日键）改为按 `startTime` 本地自然日分组；抽出主页专用日键辅助，避免改预测路径的 `historyHomeDisplayInstant`
- [x] 1.2 将 `aggregateTodayTotals` 泛化为按指定自然日聚合（`aggregateDayTotals` 或等价）；过滤日键与 1.1 一致

## 2. 吸顶头：日期 + 汇总 + 可变高度

- [x] 2.1 扩展 `HomeHistoryDateHeader` / Delegate（或并列组件）：日期文案 + 该日 chip；无 totals 时仅日期
- [x] 2.2 `SliverPersistentHeader` extent 随内容测高可变；接入 `HomeHistoryScroll` 按日传入 totals
- [x] 2.3 chip 视觉复用今日汇总 chip（logo / 品牌色 / `eventId`），挂 `onChipTap`

## 3. Sheet：TrendDayDetailChart + 异步统计

- [x] 3.1 实现玻璃 Sheet：本地筛该日该 `eventId` → `TrendPoint` 列表 → 嵌入 `TrendDayDetailChart`
- [x] 3.2 chip 点击走 3.1；确认不调用 `showHomeEventHourlyTrendSheet`
- [x] 3.3 `ClientUsageEvents` 增加 `feeding_day_summary_chart_open`（或等价稳定 id）；打开 Sheet 路径 `unawaited(reportEvent)`，不阻塞、失败静默

## 4. 卸独立今日汇总

- [x] 4.1 `home_screen` 移除身份头与历史之间的 `HomeTodaySummaryPanel`；删除或内联废弃面板以免死代码

## 5. 验收

- [ ] 5.1 手工：跨午夜已结束计时落在 start 日；滚昨天见昨天 chip；点 chip 出单日图（计次时间线 / 计时折线）；无今昨双折线；身份头下无独立今日条；Debug 可见 usage 上报且 Sheet 不卡顿
- [x] 5.2 不新建 `**/test/**`
