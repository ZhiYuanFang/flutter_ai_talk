## 1. 行模型与 lastAt

- [x] 1.1 `SmartPredictionRow` 增加 `DateTime? lastAt` 字段
- [x] 1.2 `buildSmartPredictionRows`：对每个 root 用 `occurrenceInstant(..., includeActive: true)` 取 max 写入 `lastAt`
- [x] 1.3 可选：`format_widget_relative_time.dart` 增加 `formatPredictionLastOccurrenceLabel(name, lastAt, now)`

## 2. 卡片 UI

- [x] 2.1 `_PredictionEventCard` 第二行改为左右分布（relativeText 左、toggleCaption 右）
- [x] 2.2 第三行：热态且非计时且非骨架时靠左展示「上一次{titleName}：时间」
- [x] 2.3 推演关闭、列表态、网格/瀑布态共用同一逻辑验证

## 3. 静态检查与验收

- [x] 3.1 `flutter analyze`（`smart_prediction_rows.dart`、`smart_prediction_screen.dart`、`format_widget_relative_time.dart`）
- [ ] 3.2 手工：overdue 网格 caption 左右分布 + 上一次；列表 upcoming + 上一次
- [ ] 3.3 手工：推演关有上一次；计时中无上一次；未登录骨架无上一次
- [x] 3.4 未改 `app/android/**`；本 change 不强制 release APK
