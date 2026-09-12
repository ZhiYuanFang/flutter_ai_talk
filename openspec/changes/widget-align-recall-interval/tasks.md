## 1. 预览对齐间隔旁路

- [x] 1.1 `HomeWidgetLargePreview`：`predictAllUpcoming` 传入 `inputs.recallIntervalsByRoot`（按需滤推演关闭）
- [x] 1.2 `HomeWidgetSettingsSection`：改用 `resolveWidgetPredictionInputs` + 带间隔的 `predictAllUpcoming`

## 2. 种子变更推桌面

- [x] 2.1 `upsertSeed` / `clearSeeds` 成功后 `scheduleHomeWidgetSync(ref)`
- [x] 2.2 确认不破坏 `scheduleHomeWidgetSync` 延迟/单飞约定

## 3. 验收

- [x] 3.1 手工：写间隔后预测页有 countdown；不点刷新或点刷新后，展示页预览与桌面一致
- [x] 3.2 手工：设置页预览不再仅因无种子间隔而空白
- [x] 3.3 `dart analyze` 相关文件；不新建 `**/test/**`；无 `app/android/**` 必改
