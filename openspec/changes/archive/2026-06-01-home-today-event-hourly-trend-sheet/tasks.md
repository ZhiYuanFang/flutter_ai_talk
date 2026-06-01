## 1. 数据聚合

- [x] 1.1 在 `trend_series_bucket.dart` 新增 `fillTrendBucketsHourlyFullDay`（固定 24 桶，缺失补 0）
- [x] 1.2 新增 `aggregateHourlyDualDayFromHistory(items, eventId)`：今/昨各 24 点，过滤 `countsTowardTodayTotal` 与事件键
- [x] 1.3 在 `remote_trends_repository.dart`（或新 helper）新增 `loadPieceHourlyDualDay(eventId)`：单次 piece 昨日 0:00–今日 23:59:59 → 分日分桶

## 2. 图表组件

- [x] 2.1 新建 `home_event_hourly_trend_chart.dart`：`LineChart` 双序列、竖屏 X5/Y3、横屏 X7/Y5、玻璃色轴与网格
- [x] 2.2 全零时 `maxY=1` 保证 0 基线可见；无数据不显示空态文案

## 3. 玻璃 Sheet

- [x] 3.1 新建 `showHomeEventHourlyTrendSheet`：透明 modal + `HistoryEditGlassPanel` + Logo/标题/图例
- [x] 3.2 实现 local-first → API refresh 状态与加载指示
- [x] 3.3 `HomeTodaySummaryPanel`：`_TodayChip` 增加 `onTap` 并接入 Sheet

## 4. 集成与验证

- [x] 4.1 `home_screen` 传入 `historyItems` 或 ref 供 Sheet 读取本地列表
- [x] 4.2 手工：点 chip、竖/横屏轴标签数、进行中计时不出现、无数据零线、API 刷新后曲线更新
- [x] 4.3 确认 go_ai_talk MVP 无需改动；若 piece 参数有误仅修 Flutter 调用

## 5. 横屏紧凑头区（为图表腾高度）

- [x] 5.1 横屏：Logo/事件名/图例/加载指示单行横向排布并缩小字号与图标
- [x] 5.2 横屏：玻璃面板减小内边距；图表区 `Expanded` 占满剩余高度

## 6. 昨日折线样式

- [x] 6.1 昨日线使用与今日 accent 区分的对比色，并设置 `dashArray` 虚线
- [x] 6.2 图例「昨日」圆点颜色与图表昨日线一致

## 7. 昨日折线微调

- [x] 7.1 昨日线改回实线（移除 dashArray）
- [x] 7.2 昨日线/图例使用对比色 0.7 不透明度

## 8. 昨日折线弱化

- [x] 8.1 昨日线宽 1.25（今日 2.5）
- [x] 8.2 昨日线/图例透明度 0.3

## 9. 昨日线随主题色

- [x] 9.1 昨日色由事件 accent 向白混合（浅色系），图例与折线一致
