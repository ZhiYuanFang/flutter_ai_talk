## Context

- **现状**：`TrendsScreen` 使用 `Scaffold` + Material 事件选择条 + `SegmentedButton`；`_TrendLineAndBar` 上下分栏（flex 5 折线 + flex 4 柱图），主题色轴与 `Colors.black26` 边框。
- **参照**：`HistoryEditGlassPanel`、`home_event_hourly_trend_chart.dart` 轴/网格色；主页 shell 自适应主题。
- **数据**：`TrendsRepository.loadSeries(eventKey, TrendRange)` → `TrendSeries.points`；量值计算已在 repository/metric 层，UI 不改。

## Goals / Non-Goals

**Goals:**

- 趋势页图表区玻璃拟态，单柱图全高展示。
- 顶栏控件可读（深/浅 shell 下事件条与 Segmented 不违和）。
- 空态、加载、登录遮罩行为与现网一致。

**Non-Goals:**

- 不改 piece 请求参数与聚合桶逻辑。
- 不新增趋势导出、多事件对比。
- 不重做事件选择 Sheet（可二期玻璃化 picker）。

## Decisions

1. **图表组件拆分**  
   - **选择**：新建 `_TrendsGlassBarChart`（或 `trends_glass_bar_chart.dart`），仅 `BarChart`；删除 `LineChart` 与 `spots`。  
   - **备选**：保留类名 `_TrendLineAndBar` 仅留柱 — 易误导，重命名。

2. **玻璃容器**  
   - **选择**：图表外包 `HistoryEditGlassPanel`（`eventAccent: resolveEventColor`），内边距 16；AppBar 仍用系统 `AppBar`（与历史编辑全屏页一致）。  
   - **备选**：整页 `Scaffold` 深色 — 与主页 shell 冲突。

3. **轴与柱样式**  
   - 轴标签：`HistoryEditGlassPanel.glassLabelColor`；网格 `Colors.white @ 0.12`；边框 `0.18`。  
   - 柱：`accentColor` alpha 0.85，圆角顶，宽度随点数自适应（今日点多则窄柱）。  
   - Y 轴留白 `maxVal * 1.15`，与现逻辑相同。

4. **布局**  
   - Column：Y 轴说明（小字 glassLabel）→ `Expanded` 玻璃面板 → 柱图。  
   - 移除「趋势」「量柱」双标题，仅保留一条纵轴说明。

5. **事件选择条**  
   - **MVP**：`HistoryEditGlassTapField` 或半透明白底条 + Logo/名称，替换 `themePrimaryBlend` Material 块；picker Sheet 仍可 Material，二期可玻璃化。

## Risks / Trade-offs

- **[Risk] 浅 shell 上玻璃面板对比不足** → 固定玻璃渐变底 + 浅色字（与编辑 Sheet 同策略）。  
- **[Risk] 用户习惯折线趋势** → 产品明确去掉；主页今日 chip Sheet 仍保留双折线对照。  
- **[Risk] 单图后柱过密** → 今日保留横轴抽稀（0/mid/end）；周/月/季沿用现 `_bottomSideTitles` 规则。

## Migration Plan

- 单 PR 替换 `trends_screen.dart` UI；无数据迁移。  
- 回滚：恢复 `_TrendLineAndBar` 双图实现。

## Open Questions

- 事件选择底部 Sheet 是否本迭代玻璃化 — **默认否**，仅图表区玻璃。
