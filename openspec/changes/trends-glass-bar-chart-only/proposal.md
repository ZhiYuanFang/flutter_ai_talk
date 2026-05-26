## Why

趋势中心当前为默认 Material 布局，且同时展示**趋势折线图**与**量柱图**，信息重复、视觉与主页玻璃拟态不一致。产品希望趋势页对齐玻璃风格，并**只保留量柱**表达各时间桶的累计量，降低认知负担、腾出图表高度。

## What Changes

- **玻璃态主视觉**：趋势页图表区采用与历史编辑/今日趋势 Sheet 一致的玻璃容器（磨砂渐变、事件色 tint、浅色轴标签与网格）；顶栏事件选择、时间范围 Segmented 控件样式与 shell 协调。
- **移除趋势折线**：删除 `LineChart` 及「趋势」标题区块；页面 MUST NOT 再展示折线图。
- **仅保留量柱**：单一 `BarChart` 占满图表区；纵轴语义不变（计时类为小时、计数类为次数）；横轴与空态、加载态保留。
- **行为保持**：事件目录单选、今日/周/月/季范围、`loadSeries`、`event_number==0` 时段计量、未登录遮罩与 `/trends` 路由不变。
- **非目标**：后端 piece API 变更；主页今日 chip 小时双折线 Sheet。

## Capabilities

### New Capabilities

- `trends-center-glass-bars`：趋势中心玻璃态布局、仅量柱图表、事件选择与时间范围交互规范。

### Modified Capabilities

- `trends-center-event-charts`（变更 `trends-center-event-picker-bars`）：由「折线 + 量柱」改为「仅量柱」；图表呈现要求更新。

## Impact

- `app/lib/ui/trends_screen.dart` — 重构 `_TrendLineAndBar` 为玻璃量柱组件；移除折线
- 复用：`home_history_edit_glass_panel.dart`（或抽取轻量 `TrendsGlassChartPanel`）
- 可选：`event_logo`、玻璃色常量、`AppVisualTokens` / `themePrimaryBlend`
- 无 API 变更
