## Context

喂养主页当前在沉浸身份头与历史列表之间挂载 `HomeTodaySummaryPanel`，用 `aggregateTodayTotals` 聚合「今天」总额；历史列表另有按日 `SliverPersistentHeader` 吸顶（`HomeHistoryDateHeader`，固定约 30px）。日分块键取自 `historyHomeDisplayInstant`：已结束计时（`eventNumber==0` 且 end 已设）用 **end**，跨午夜睡眠会整段落在结束日。chip 曾禁止打开今昨小时 Sheet；产品现要按日汇总 + 单日详图。

## Goals / Non-Goals

**Goals:**

- 去掉独立「今日汇总」挂载位；按日汇总进入日期吸顶。
- 吸顶：日期 + 该日 `eventId` 聚合 chip；无总额时仅日期；高度随 chip 折行可变。
- chip 点按打开玻璃 Sheet，复用 `TrendDayDetailChart`（单日；计次时间线 / 时长折线）。
- 打开 Sheet 时经 `clientUsageReporter` **异步**上报统计（不阻塞 UI）。
- 汇总与 Sheet 序列均从主页**本地已加载**历史快照派生；更旧日随既有 `loadMore` 出现。
- 主页日分块键改为 **`startTime` 本地自然日**（仅喂养历史分组/汇总/该 Sheet）。

**Non-Goals:**

- 新增日汇总 / 日详图专用 HTTP；改 `pageSize` 或分页协议。
- 改预测分桶、`historyHomeDisplayInstant` 在预测/相对 ago 等路径的语义（除非实现时抽「仅分组用」辅助函数，避免误伤）。
- 恢复今昨双日小时 Sheet 作为喂养 chip 入口；趋势中心 `/trends` 既有入口不动。
- 为无记录的「空日历日」人造日块（无记录则无分块）。
- 新造并行统计通道（必须走既有 client-usage）；改服务端限流策略。
- 自动新建 `**/test/**`。

## Decisions

1. **吸顶组合头，取代独立今日区。**  
   扩展 `HomeHistoryDateHeader`（或并列 delegate）：上日期文案，下该日 chip Wrap；`minExtent`/`maxExtent` 按内容测高（post-frame 或预估），替代固定 `height=30`。  
   备选：列表外 sticky Overlay —— 与现有 per-section Sliver 吸顶冲突，放弃。

2. **日键 = `startTime`（主页分组专用）。**  
   `buildHomeHistoryDayGroups`（及按日聚合）用 `parseHistoryInstant(startTime)`（缺失回退 `createdAt` 等既有规则），**不用** finished-end 的 `historyHomeDisplayInstant`。行内 `HH:mm` / 文案仍可沿用既有 display instant，避免大改 `history-line-display`。  
   备选：全局改 `historyHomeDisplayInstant` 为 start —— 会波及相对 ago、预测对照，Non-Goal。

3. **聚合：按日复用今日聚合语义。**  
   将 `aggregateTodayTotals` 泛化为「给定日窗口 + 记录列表 → `List<TodayEventTotal>`」（或 `aggregateDayTotals(day, records)`）；过滤键与日块一致（start 日）。chip 仍按 `eventId` + 目录 logo/品牌色。

4. **Sheet：复用 `TrendDayDetailChart`，本地造点。**  
   从该日本地记录筛出所选 `eventId`，映射为 `List<TrendPoint>`（计次 occurrence / 计时时长小时），传入既有图表；容器用 `HistoryEditGlassPanel`（或与编辑 Sheet 同族玻璃）。  
   **不得**调用 `showHomeEventHourlyTrendSheet`。  
   备选：跳转 `/trends` —— 打断喂养上下文，放弃。

5. **打开汇总图时异步 usage 上报。**  
   在确认打开 Sheet 的同一用户手势路径上，`unawaited(ref.read(clientUsageReporterProvider).reportEvent(...))`（或等价 fire-and-forget）；**不得** `await` 上报后再 `showModalBottomSheet`。  
   在 `ClientUsageEvents` 新增稳定 `featureId`（建议 `feeding_day_summary_chart_open`）与中文 `description`（可含事件显示名；**不得**含 `|`）。未登录不报（既有 reporter 门闸）。  
   备选：仅 Debug 本地 log —— 不满足运维统计，放弃。

6. **本地分页边界。**  
   仅对当前内存列表中已出现的自然日展示吸顶汇总；用户触顶 `loadMore` 后新日块自然出现。Sheet 无数据时走图表既有空态（空时间线 / 空坐标），不因此强制拉远程。

7. **空日（无有效总额）。**  
   日块因有记录而存在，但聚合结果为空时：吸顶 **仅日期**，chip 区 shrink；高度回落到日期行。

8. **卸载。**  
   `home_screen` 去掉 `HomeTodaySummaryPanel`；`HomeTodaySummaryPanel` 可删可改为按日 chip 子组件复用，实现任选，行为以 spec 为准。

## Risks / Trade-offs

- [跨午夜记录改日] → 睡眠等归开始日；与旧「结束日」视觉不一致，属产品意图；预测路径勿误改。  
- [可变吸顶高度抖动] → 测高稳定后再更新 extent；同日 totals 不变不重建。  
- [仅本地页深度] → 未 loadMore 的更早日无汇总；依赖既有分页，不加深默认拉取。  
- [chip 与行时刻日不一致] → 行 `HH:mm` 仍可能按 end 显示，但落在 start 日块；在 design 接受，文案不强制改行时刻。  
- [Sliver 多 section 性能] → 保持每节一个 header delegate；避免全局 setState。

## Migration Plan

1. 改日键与按日聚合 → 扩展吸顶 UI → 接 chip→Sheet → 移除独立今日汇总。  
2. 手工：跨午夜睡眠落开始日；滚昨天见昨天 chip；点 chip 出单日图；无今昨双折线；今日区不再夹在身份头下。  
3. 回滚：恢复 `HomeTodaySummaryPanel` + 固定日期头 + 原分组 instant。

## Open Questions

- （已定）日键 start；空汇总仅日期；Sheet=`TrendDayDetailChart`；本地快照；打开 Sheet 异步 usage。  
- `featureId` 定名：实现用 `feeding_day_summary_chart_open`（若与字典冲突可微调，须写入 `ClientUsageEvents` 并保持稳定）。  
- 行内时间是否也改 start：本 change **不改**，除非实现中发现强不一致再开 follow-up。
