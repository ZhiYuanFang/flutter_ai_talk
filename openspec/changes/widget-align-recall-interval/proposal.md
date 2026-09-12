## Why

统一间隔旁路后，预测页在样本不足时已能用 `seed.interval` 出 countdown，但桌面小组件与页内预览仍常显示「无预测」：写种子不触发 sync；大尺寸预览漏传 `recallIntervalsByRoot`；用户点「刷新小组件数据」后预览仍像没更新。需让小组件表面与预测页同源。

## What Changes

- `HomeWidgetLargePreview` 调用 `predictAllUpcoming` 时 **必须**传入 `resolveWidgetPredictionInputs` 的 `recallIntervalsByRoot`（与 native sync 一致）。
- `upsertSeed` / `clearSeeds` 成功后 **必须** `scheduleHomeWidgetSync`，使桌面 payload 随种子变更更新（不必依赖用户手动刷新）。
- 设置页小组件预览 **必须**改走与预测页同源输入（真历史 ∪ 间隔旁路），不得仅用 `homeHistory` 且无种子间隔。
- 本 change **不**改推演公式本身（以 `unify-prediction-interval-branch` 为准）；**不**新建 `**/test/**`；无 `app/android/**` 必改。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-feed-upcoming-widget`：小组件预测输入须与预测页同源（含回忆间隔旁路）；种子变更须调度 sync；页内/设置预览不得漏传间隔。

## Impact

- `home_widget_large_preview.dart`、`prediction_recall_provider.dart`（upsert/clear 后 sync）、`home_widget_settings_section.dart`。
- 对照基线 `openspec/specs/v2.1.0.md` 小组件/预测相关能力；间隔旁路语义承接 `unify-prediction-interval-branch`。
- 手工：写间隔后桌面/预览出 countdown；点刷新预览与预测页一致。
