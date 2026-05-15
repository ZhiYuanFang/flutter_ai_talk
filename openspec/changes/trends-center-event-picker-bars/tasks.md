## 1. 数据层

- [x] 1.1 在 `RemoteTrendsRepository`（或独立 `trend_point_mapper.dart`）中实现从 `piece` 单条 `Map` 到「时间 + 折线值 + 柱值」的映射：`eventNumber == 0` 用 `endTime-startTime` 换算为**小时**，否则用 `eventNumber` 数值；复用/对齐 `parseHistoryInstant` 与未结束语义。
- [x] 1.2 `loadSeries` 返回结构扩展或新增 DTO（如 `TrendChartSeries`），包含排序后的点列表，供 UI 同时绑折线与柱。

## 2. 趋势中心 UI

- [x] 2.1 将 `TrendsScreen` 改为顶部事件 **Dropdown**（或等价）+ 既有时间范围 `SegmentedButton`；移除「进入即对所有事件并发拉 piece」的逻辑，改为**选中项变化或范围变化时**仅拉当前 `eventKey`。
- [x] 2.2 使用 `fl_chart` 实现 **折线图 + 柱状图**（上下布局或组合），共享横轴刻度策略；无数据时展示占位文案。
- [x] 2.3 登录蒙层、无 `deviceNo` 等与现有行为保持一致。

## 3. 测试与文档

- [x] 3.1 为量值映射编写 `flutter_test`：`eventNumber==0` 有效起止、`end` 缺失、`eventNumber>0` 三类样例 Map。
- [x] 3.2 `flutter analyze` 通过；必要时在 `README` 趋势小节补一句「单事件 + 折线/量柱」说明。
