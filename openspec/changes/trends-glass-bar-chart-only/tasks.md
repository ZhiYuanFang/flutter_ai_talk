## 1. 图表重构

- [x] 1.1 将 `_TrendLineAndBar` 重命名为 `_TrendsGlassBarChart`（或独立文件），移除 `LineChart` 与折线相关 `spots`
- [x] 1.2 单 `BarChart` `Expanded` 占满图表区；删除「趋势」「量柱」双标题，保留纵轴说明

## 2. 玻璃视觉

- [x] 2.1 柱图外包 `HistoryEditGlassPanel`（`eventAccent`）；轴/网格/边框使用玻璃浅色样式
- [x] 2.2 柱体颜色使用事件 accent；空态/加载在玻璃容器内居中

## 3. 顶栏与集成

- [x] 3.1 事件选择条改为玻璃质感可点击条（Logo + 名称 + 展开图标）
- [x] 3.2 确认 Segmented 范围切换、`loadSeries`、登录遮罩行为不变

## 4. 验证

- [x] 4.1 手工：四档时间范围、计时/计数事件、无数据空态、未登录遮罩
- [x] 4.2 确认无残留 `LineChart` import 仅用于趋势页（或移除未用 import）

## 5. 轴标签粒度（对齐主页今日趋势）

- [x] 5.1 抽取 `ChartAxisGranularity`：今日整点 X 用 0/6/12/18/23（竖）与 0/4/8/12/16/20/23（横）；周月季均匀 5/7 档
- [x] 5.2 纵轴竖屏 3 档、横屏 5 档；主页小时趋势图复用同一工具
