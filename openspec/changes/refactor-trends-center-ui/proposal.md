# refactor-trends-center-ui 提案

## Why

当前趋势中心存在顶部 AppBar 与双胶囊筛选区，图表区域未达到沉浸式全屏视觉；事件选择入口与日期选择入口分散，用户在查看趋势时需要频繁在页面顶部与图表区之间切换注意力。为统一交互路径并提升趋势阅读效率，需要将趋势中心重构为“图表头部即控制区”的结构。

## What Changes

- 将趋势中心改为全屏趋势图背景布局，移除页面标题栏（AppBar）。
- 将事件选择入口迁移到趋势图标题：点击标题可打开事件选择，标题右侧显示下拉箭头表示可切换。
- 在趋势图标题下方展示日期范围文案；点击日期范围可打开日期范围选择 Sheet。
- 在趋势图标题上方展示当前事件 logo，形成“logo → 标题 → 日期范围”的头部层级。
- 移除图表内“纵轴含义说明”文本，仅保留坐标与数据表达。
- 保持既有数据与记忆能力：事件记忆、日期范围记忆、趋势序列加载逻辑继续生效。

## Capabilities

### New Capabilities

- `trends-center-chart-header-actions`: 趋势中心图表头部承载事件选择与日期范围选择交互，并展示事件 logo 与可选择状态。

### Modified Capabilities

- `trends-center-date-range-ui`: 日期范围入口从顶部胶囊迁移到图表标题下方，交互入口与布局要求调整。
- `trends-center-glass-bars`: 图表区结构从“图表标题+纵轴语义文本”调整为“logo/可点击标题/可点击日期范围”，移除纵轴语义说明文案。
- `event-branded-ui`: 趋势中心当前选中事件的 logo 展示位置从顶部筛选区调整到图表标题上方，保持品牌一致性。

## Impact

- Flutter UI：
  - `app/lib/ui/trends_screen.dart`（页面骨架、AppBar 与顶部筛选区移除、交互入口迁移）
  - `app/lib/ui/trend_glass_bar_chart.dart`（图表头部结构与点击回调、纵轴文案移除）
- 交互复用：继续复用既有事件选择 Sheet 与日期范围 Sheet（无需新增接口协议）。
- OpenSpec：新增 `trends-center-chart-header-actions` 能力规格，并更新上述已存在能力的需求描述与场景。
