## 1. 单位文案

- [x] 1.1 在 `trend_metric_format.dart` 增加 `trendYAxisUnitLabel`：`time`→「时长」、`one`→「次」、否则 `unit.trim()` 空则「量」

## 2. 图表接入

- [x] 2.1 `TrendNDayBarChart`：Y 轴顶部展示 `trendYAxisUnitLabel`（含计次柱图）
- [x] 2.2 `TrendDayDetailChart` 折线态：Y 顶展示单位；计次时间轴分支 MUST NOT 加该文案
- [x] 2.3 确认 `trends_screen` 已传入 `eventType`/`unit`；缺则补齐

## 3. 验收

- [x] 3.1 手工：计时「时长」、计数有 unit、计数空→「量」、计次柱「次」且时间轴无 Y 单位
- [x] 3.2 确认未新建 `**/test/**`、未改 `app/android/**`

## 4. 位置修正

- [x] 4.1 单位改为绘图区上方、对齐 Y 轴列（Column），避免与居中标题/顶刻度重合
