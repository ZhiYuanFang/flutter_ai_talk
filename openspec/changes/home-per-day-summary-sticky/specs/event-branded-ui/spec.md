## REMOVED Requirements

### Requirement: 今日汇总展示

**Reason**: 独立「今日」汇总挂载在身份头与历史之间，无法随滚动反映昨天/更早日；产品改为按日吸顶汇总（见 `home-per-day-summary-sticky`）。

**Migration**: 卸下 `HomeTodaySummaryPanel`（或等价）在身份头与历史之间的挂载；按日总额改由日期吸顶 chip 展示；logo/品牌色与按 `eventId` 聚合语义迁移到 `home-per-day-summary-sticky`。不得再验收「今日区夹在身份头与历史之间」。
