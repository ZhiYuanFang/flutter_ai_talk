## Why

趋势中心已完成玻璃量柱与轴粒度对齐，但顶栏仍为「今日/周/月/季」四档固定区间，与产品参考稿（双胶囊 + 自定义时段 + 固定「喂养趋势图」标题）不一致。用户需要按**起止日期**查看最多 **30 天**内的量柱趋势，且下次进入可恢复上次选择的日期范围；视觉延续主页**主题色深色玻璃**，柱体为**事件 accent 单色渐变**并尽量立体。

## What Changes

- **时段**：移除 `TrendRange` 分段控件；右胶囊展示并可修改**开始日～结束日**（本地自然日）；单次查询跨度 **不得超过 30 天**（含起止两日）。
- **范围记忆**：将上次确认的起止日期持久化（`SharedPreferences`）；再次打开趋势中心时恢复；若记忆非法或超 30 天则回退默认（建议：**本周一至今天**）。
- **顶栏布局**：左胶囊「选择事件」+ Logo + 事件名；右胶囊「选择时段范围」+ 日期区间展示 + 日历入口（结构对标参考图，材质为玻璃非浅色 clay）。
- **图表区**：玻璃面板内固定居中标题 **「喂养趋势图」**；仅量柱图；纵轴说明保留；轴标签粒度沿用 `ChartAxisGranularity`（同日按整点 5/7 档，跨日按均匀 5/7 日期档）。
- **柱体视觉**：`BarChart` 柱使用事件 **accent 线性渐变**（顶亮底暗）+ 较大顶圆角，营造轻度 3D 感；不按桶多色。
- **数据层**：`TrendsRepository.loadSeries` 改为接收 `startDate`/`endDate`（或等价），`piece` 查询 `startTime`/`endTime` 为起日 0:00 至止日 23:59:59；分桶：同日→按小时，跨日→按自然日（复用 `trend_series_bucket.dart`）。
- **非目标**：浅色育儿 clay 全页、柱内装饰图标、后端 API 契约变更、折线图回归。

## Capabilities

### New Capabilities

- `trends-center-date-range-ui`：双胶囊顶栏、起止日期选择、30 天限制、范围记忆、固定标题与渐变量柱呈现。

### Modified Capabilities

- `trends-center-glass-bars`（变更 `trends-glass-bar-chart-only`）：时间维度由四档枚举改为日期区间；分桶模式由 `TrendRange` 推导改为按区间跨度推导。
- `trends-center-event-charts`（变更 `trends-center-event-picker-bars`）：移除四档 `TrendRange` 作为唯一时间输入的假设。

## Impact

- `app/lib/ui/trends_screen.dart`、`trend_glass_bar_chart.dart`
- 新建 `trends_date_range_store.dart`（或 `config/` 下记忆 Store）
- `app/lib/data/repositories.dart`、`remote_trends_repository.dart`、`trend_series_bucket.dart`
- `app/lib/ui/chart_axis_granularity.dart`（`hourlyToday` → `bucketMode`）
- 无 go_ai_talk 后端变更（继续 `GET /device/history/api/piece`）
