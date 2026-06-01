## 1. 数据与记忆

- [x] 1.1 新增 `TrendsDateRangeStore`：`save`/`load` 起止日（ISO）；默认本周一至今天
- [x] 1.2 `TrendsRepository.loadSeries(eventKey, startDate, endDate)`；`RemoteTrendsRepository` 用起止日换算 `startTime`/`endTime`
- [x] 1.3 `normalizeTrendSeriesForBounds`：同日按小时、跨日按自然日；移除趋势路径对 `TrendRange` 的依赖
- [x] 1.4 跨度 >30 日历日校验与 toast

## 2. 趋势页顶栏

- [x] 2.1 移除 `SegmentedButton<TrendRange>`；左右玻璃胶囊布局
- [x] 2.2 右胶囊：`showDateRangePicker`（或等价）+ 展示 `MM-dd — MM-dd`；确认后写记忆并刷新
- [x] 2.3 进入页时 `load` 记忆范围并 `_loadSeries`

## 3. 图表区

- [x] 3.1 `TrendGlassBarChart`：固定标题「喂养趋势图」；参数改为日期 + `bucketMode`
- [x] 3.2 柱体 accent `LinearGradient` + 顶圆角（轻 3D）；`ChartAxisGranularity` 按 hourly/daily
- [x] 3.3 空态/加载/登录遮罩回归

## 4. 验证

- [x] 4.1 手工：30 天边界、31 天拒绝、记忆恢复、同日/跨日分桶、竖横屏轴档数
- [x] 4.2 `dart analyze` 趋势相关文件无新增告警

## 5. 主题可读性（经典浅色）

- [x] 5.1 趋势顶栏胶囊：`onShell` + `historyEditGlassShellTextColor`，经典主题下深色字可读

## 6. 日期范围玻璃 Sheet

- [x] 6.1 `showTrendsDateRangeGlassSheet`：透明底 + `HistoryEditGlassPanel`，双 `CupertinoDatePicker`（开始/结束）
- [x] 6.2 趋势页替换 `showDateRangePicker`；30 天校验与确定按钮样式对齐 number/历史编辑

## 7. 图表标题随事件

- [x] 7.1 玻璃区内标题为「{事件名}趋势图」，随选中事件更新
