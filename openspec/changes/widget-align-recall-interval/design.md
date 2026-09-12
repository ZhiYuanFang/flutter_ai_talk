## Context

`unify-prediction-interval-branch` 已让 `predictAllUpcoming` 支持 `recallIntervalsByRoot`，且 `syncHomeWidgetFromRef` / `resolveWidgetPredictionInputs` 已接旁路。缺口在消费侧：页内 large 预览漏传间隔；种子 upsert/clear 不 schedule sync；设置页预览仍只用 home 分页。用户点「刷新」后预览仍错，体感「刷新也没更新」。

## Goals / Non-Goals

**Goals:**

- 页内 large 预览、设置预览、native sync 与预测页同一套真历史 + 间隔旁路。
- 种子写入/清除后桌面自动 sync。

**Non-Goals:**

- 不改加权中位 / 种子公式。
- 不改 native Kotlin/Swift 布局。
- 不新建测试。

## Decisions

### D1：预览必须传 `recallIntervalsByRoot`

**选择**：`HomeWidgetLargePreview` 在 `predictAllUpcoming` 增加 `recallIntervalsByRoot: inputs.recallIntervalsByRoot`（并按 disabled 过滤若需要，与 sync 一致）。

### D2：种子变更调度 sync

**选择**：`PredictionRecallSeedsNotifier.upsertSeed` / `clearSeeds` 成功更新 state 后 `unawaited(scheduleHomeWidgetSync(ref))`。

**注意**：遵守现有「下一 event-loop turn」约定，避免 notifier 栈内 read 同源 provider 断言失败（沿用 `scheduleHomeWidgetSync` 已有延迟）。

### D3：设置页预览同源

**选择**：`HomeWidgetSettingsSection` 改用 `resolveWidgetPredictionInputs(ref)` + 带间隔的 `predictAllUpcoming`，替换仅 `homeHistoryProvider` 路径。

## Risks / Trade-offs

- **[Risk] seeds Async 未就绪时间隔 map 空** → sync/预览与预测页同样依赖 `asData`；可接受；用户已在预测页看到种子则 map 通常已有。  
- **[Trade-off] clearSeeds 频繁 microtask 清空根** → 已有逻辑；额外 sync 合并靠 single-flight。

## Migration Plan

发版后旧「无预测」payload 在下次种子写或手动刷新后被正确预测覆盖。

## Open Questions

（无）
