## 1. 小组件预测输入对齐

- [x] 1.1 `syncHomeWidgetFromRef` / `buildHomeWidgetPayload`：历史改为读 `predictionHistoryWithRecallSeedsProvider`（或等价 merge），移除默认 `homeHistoryProvider.items`
- [x] 1.2 catalog 改为 `eventCatalogProvider.items`；移除 widget sync 内单独 `EventCatalogStore.loadFromDisk()` 主路径
- [x] 1.3 `predictAllUpcoming` 前应用 `forecastDisabledIdsProvider` 过滤，与预测页一致
- [x] 1.4 active timing 检测改为基于 range merge 历史（与 `smartPredictionRowsProvider` 一致，可 union home 仅当仍需要即时 WS 未入 range 的极短窗口——优先仅 range+home active keys 并集，与现有 smart provider 相同）

## 2. Widget sync 触发补全

- [x] 2.1 `PredictionRangeHistoryNotifier._loadImpl` 成功写 ready state 后 `unawaited(scheduleHomeWidgetSync(ref))`
- [x] 2.2 在 `app.dart` 或主壳增加 `ref.listen(predictionRangeHistoryProvider, …)`：ready/items 边沿变化时 schedule sync（非 provider 构造自动 ensure）
- [x] 2.3 `homeHistoryNotifier.refreshFromRemote` 的 `firstPageOnlyCached` 早退：补 `scheduleInvalidation()` + `scheduleHomeWidgetSync`
- [x] 2.4 `homeHistoryNotifier._applyState` / WS 路径：保留 range 失效；`scheduleHomeWidgetSync` 不再传 home-only `historyOverride`（或移除 override 语义）

## 3. 清理与静态检查

- [x] 3.1 更新 `home_widget_sync.dart` 注释与 `historyOverride` 文档（弃用或忽略 home 快照）
- [x] 3.2 `flutter analyze` 通过（`app/lib/home_widget/**`、`prediction_range_history_provider.dart`、`home_history_notifier.dart`）

## 4. 手工验收

- [ ] 4.1 改一条记录：预测页 hero/nextAt 与桌面小组件一致
- [ ] 4.2 冷启 / 换绑后 range loading→ready：小组件从「正在准备数据…」更新为正确预测
- [ ] 4.3 关闭某事件推演：小组件不再展示该事件预测
- [x] 4.4 未改 `app/android/**`；本 change 不强制 `flutter build apk --release`
