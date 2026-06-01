# refactor-trends-center-ui 任务清单

## 1. 页面骨架重构

- [x] 1.1 调整 `TrendsScreen` 页面结构，移除 `AppBar` 与顶部双胶囊控件区。
- [x] 1.2 保留并适配返回入口与登录遮罩，使无 AppBar 场景下导航与拦截行为一致。
- [x] 1.3 调整图表区域占位与边距，达到沉浸式近全屏显示目标。

## 2. 图表头部交互迁移

- [x] 2.1 在 `TrendGlassBarChart` 头部新增 logo 展示区，位于标题上方。
- [x] 2.2 将标题行改为可点击事件选择入口，并在标题右侧展示下拉箭头。
- [x] 2.3 在标题下方新增可点击日期范围文本入口，点击后打开日期范围 Sheet。
- [x] 2.4 复用现有 `_openEventPicker()` 与 `_openDateRangePicker()`，通过回调接入头部交互。

## 3. 图表文案与语义对齐

- [x] 3.1 移除图表内“纵轴含义说明”文本，不再展示额外语义提示。
- [x] 3.2 保持柱图纵轴计算语义不变（计时类为小时、计数类为次数）。
- [x] 3.3 确认单日/跨日分桶与 `ChartAxisGranularity` 抽稀策略不受本次 UI 改造影响。

## 4. 规格映射与回归验证

- [x] 4.1 按 `trends-center-chart-header-actions` 验证标题点击、箭头可见、日期点击与 logo 层级。
- [x] 4.2 按修改后的 `trends-center-date-range-ui` 验证日期入口位置迁移与范围记忆恢复。
- [x] 4.3 按修改后的 `trends-center-glass-bars` 验证无 AppBar 沉浸布局与纵轴说明移除。
- [x] 4.4 按修改后的 `event-branded-ui` 验证趋势中心头部 logo 与品牌色一致性。
- [x] 4.5 更新任务勾选与验收记录，确保每项任务可追溯到对应 Requirement/Scenario。

## 5. 验收记录（本次实现）

- 代码改动：
  - `app/lib/ui/trends_screen.dart`：移除 `AppBar` 与顶部双胶囊，改为沉浸式图表主视图；新增浮层返回按钮；将事件/日期选择入口迁移至图表头部回调。
  - `app/lib/ui/trend_glass_bar_chart.dart`：新增头部 logo、可点击标题（含下拉箭头）、可点击日期范围文本；移除纵轴语义说明文案。
- 规格映射：
  - `trends-center-chart-header-actions`：覆盖“标题点击可选事件”“箭头可见”“日期点击打开范围选择”“logo 位于标题上方”。
  - `trends-center-date-range-ui`：覆盖“日期入口迁移至标题下方”“日期范围文案展示与更新”。
  - `trends-center-glass-bars`：覆盖“无 AppBar 的沉浸式布局”“纵轴说明移除且图表语义保持”。
  - `event-branded-ui`：覆盖“趋势中心头部展示选中事件 logo 并沿用品牌色”。
- 校验结果：
  - 已检查改动文件静态错误：0 errors。
  - 已执行自动化测试：8 passed / 0 failed。
