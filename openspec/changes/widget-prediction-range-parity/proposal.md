## Why

兄弟变更 `prediction-widget-seven-day-range-history` 已将预测页切到近 7 日 `predictionRangeHistoryProvider`，但桌面小组件 `syncHomeWidgetFromRef` 仍默认读取 `homeHistoryProvider.items`（喂养列表第 1 页，约 20 条）。range 单独拉取/失效重拉完成后不会触发 widget sync；`refreshFromRemote` 的 `firstPageOnlyCached` 早退路径亦跳过 sync。用户可见预测页已刷新而小组件 hero 仍 stale，违反「预测与小组件同源」产品预期。

## What Changes

- 小组件 `predictAllUpcoming` 输入改为与智能预测页一致：`predictionHistoryWithRecallSeedsProvider`（7 日 range ∪ 回忆种子），**不得**再默认用 `homeHistoryProvider` 分页深度。
- 小组件事件目录改为读取 `eventCatalogProvider`（与预测页同源），**不得**单独 `EventCatalogStore.loadFromDisk()`。
- 小组件预测 **必须** 尊重 `forecastDisabledIdsProvider`（与预测页同一推演关闭集合）。
- range store 就绪或 items 变更后 **必须** 调度既有 `scheduleHomeWidgetSync`（遵守副作用 HTTP：listen/显式回调，**不得** provider 构造自动 push）。
- 修复 `homeHistoryNotifier.refreshFromRemote` 在 `firstPageOnlyCached` 时仍 **必须** 触发 range 失效与 widget sync 的缺口（当 range 可能落后于首页缓存时）。
- `scheduleHomeWidgetSync` 的 `history` 覆盖参数语义对齐 range（或移除仅 homeHistory 快照路径，改由 sync 内读 range store）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-feed-upcoming-widget`：小组件预测历史/catalog/推演过滤与预测页同源；payload refresh 须在 range 就绪/变更时触发。
- `prediction-range-history`：range 拉取成功或 debounce 重拉完成后 **必须** 调度小组件 sync（single-flight 内，非构造启动）。

## Impact

- **Flutter**：`home_widget_sync.dart`、`home_history_notifier.dart`（`firstPageOnlyCached`）、`prediction_range_history_provider.dart` 或 `app.dart` listen、`forecast_toggle_provider` 已有 sync 可复用。
- **喂养列表**：无行为变更；widget 不再依赖其分页深度。
- **API / Android**：无新接口；不改 `app/android/**`。
- **测试**：不新建 `**/test/**`；手工验收预测页与小组件 hero/nextAt 一致、range 重拉后桌面更新。
