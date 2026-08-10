## Context

喂养 `HomeScreen`：`HomePredictionTipBar`（含「跳过」→ `WidgetHeroSkipStore`）与 `HomeTodaySummaryPanel`（今日 chip → 今昨小时 Sheet）。产品要求去掉跳过与整块今日总结。

## Goals / Non-Goals

**Goals:**

- 顶栏无「跳过」；贴士仍展示，点击进智能预测。
- tip 选条仍可尊重推演关闭与小组件 skip（仅去掉主页写 skip）。
- 主页不再挂载今日总结面板；清理仅为其服务的 totals 计算若可安全删除。

**Non-Goals:**

- 不删除 `WidgetHeroSkipStore` / 小组件 skip 能力。
- 不删除 `showHomeEventHourlyTrendSheet` 实现（可无主页入口）。
- 不改智能预测页。

## Decisions

1. **Tip：删 UI 与 `_skipTip`，保留 filter**  
   `onSkip` / TextButton 移除；`homePredictionTipProvider` 继续 reconcile skip。  
   **备选**：连 skip 过滤也去掉——拒绝，避免与小组件 hero 不一致。

2. **今日总结：去掉挂载**  
   `home_screen` 不再构建 `HomeTodaySummaryPanel`；`home_today_summary_panel.dart` 可删文件或留未引用（优先删挂载 + 死代码）。

3. **点 tip 热区**  
   整条可点进预测（原非跳过区逻辑扩展为全条）。

## Risks / Trade-offs

- [失去主页今昨小时入口] → 用户走趋势中心；产品接受。  
- [小组件仍可 skip、主页不能] → 预期；主页只读过滤。

## Migration Plan

- 纯 UI；热重载即可。

## Open Questions

- （无）
