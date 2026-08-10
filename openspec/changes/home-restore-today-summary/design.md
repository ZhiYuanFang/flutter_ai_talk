## Context

`home-remove-tip-skip-and-today-summary` 已卸下 `HomeTodaySummaryPanel` 并删文件；`aggregateTodayTotals` 与 `showHomeEventHourlyTrendSheet` 仍在。现网喂养顶为身份横条。产品只要恢复今日 chip 卡片，不要 chip→Sheet。

## Goals / Non-Goals

**Goals:**

- 恢复今日汇总面板 UI 与 `HomeScreen` 挂载。
- 保持折叠/展开、按 `eventId` 聚合、logo/品牌色与 pill 样式语义（对齐基线「今日摘要药丸样式」）。
- Chip 无导航到小时趋势 Sheet。

**Non-Goals:**

- 不恢复 tip「跳过」。
- 不强制解开 `HomePredictionTipBar` 注释。
- 不改 Sheet 实现本身（可继续闲置或供他处复用）。
- 不新建 `**/test/**`。

## Decisions

1. **从 git 恢复面板源文件**  
   以移除前 `home_today_summary_panel.dart` 为底，挂回 `home_screen`；取色优先走现网 `AppColor` / `AppVisualTokens` pill 语义，避免硬编码灰阶。

2. **接线**  
   `aggregateTodayTotals(historyItems)` → `HomeTodaySummaryPanel(totals: …)`；`onChipTap` 不传或空实现（无 Sheet）。

3. **布局**  
   身份头 →（可选间距）→ 今日总结 → 既有间距/绑定横幅/历史。空 totals 不占高。

4. **规格**  
   在 `event-branded-ui` 重新 ADDED「今日汇总展示」；在 `home-today-event-hourly-trend-sheet` ADDED「主页 chip 不得打开 Sheet」，避免与移除 change 的 REMOVED 入口冲突后再误接。

## Risks / Trade-offs

- [发现成本] 用户曾习惯点 chip 看今昨曲线 → 缓解：右上趋势仍在；若反馈强烈可另开 change 接 Sheet。  
- [与移除 change 并存] 两 change 对同一 Requirement 一删一加 → 归档顺序需注意；本 change 以「恢复展示」为准。

## Migration Plan

- 纯 UI 恢复。回滚：卸下面板挂载。

## Open Questions

（无；「只要卡片」已确认。）
