## Context

依赖未归档的 `trends-dual-chart-ux` 实现：`TrendsScreen` 双图壳、`TrendNDayBarChart`、`TrendDayDetailChart`（含计次 `_CountTimelinePainter`）。真机反馈集中在 chrome 可用性、点柱触控、折线语义与时间轴几何。

## Goals / Non-Goals

**Goals:**

- Chrome：返回入行居中；语义色图标；日期圆角 chip + ▾。
- 点柱可靠更新 `_selectedDay` 与下图。
- 非时间轴：事件色 X/Y 轴线。
- 折线：空态坐标 0–24 / 0–10 无幽灵线；有数据只连非零点。
- 时间轴：点在带心；细线长不变；时刻在带内；刻度略下移。

**Non-Goals:**

- 改范围预设、piece API、近3个月。
- 重做双图布局或飞入动画逻辑（仅返回落点行内对齐即可）。
- 同时刻标签复杂避让。

## Decisions

1. **返回入 Row**  
   去掉独立 `Positioned` 返回（或保留但改为与 chrome 同高测量）；首选将 `IconButton` 作为选择行首子项，去掉占位 `SizedBox(40)`，`crossAxisAlignment: center`。色用 `AppColor.textPrimary(context)`。

2. **日期 chip**  
   `DecoratedBox`/`InkWell`：圆角、浅白底边，文案 + `Icons.expand_more`。

3. **点柱触控**  
   在 `touchCallback` 中当 `response?.spot != null`（如 `FlTapDownEvent`）缓存 group index；在 `FlTapUpEvent` 用缓存提交 `onSelectDay`。避免只读 Up 时已清空的 spot。

4. **事件色轴线**  
   `FlBorderData` 左+底 `BorderSide(color: accentColor)`；柱图/折线共用。

5. **折线空态**  
   无 raw 时渲染 `LineChart`：`minX=0,maxX=23`（或 24 域）、`minY=0,maxY=10`，`lineBarsData: []`，无幽灵 CustomPaint 折线。

6. **有点连线**  
   小时桶后仅将 `value > 0` 的点加入 spots；相邻空洞拆多段 `LineChartBarData`（连续非零为一笔）。对齐预测页「只放有数据 spot」精神。

7. **时间轴几何**  
   背景带矩形增高或下移轴；`dotY = bandCenterY`；stem 仍约当前长度（轴心向下短段）；`HH:mm` 画在 stem 末端且 `y` 仍 `< bandBottom`；0/6/12/18/24 刻度画在带下方。

## Risks / Trade-offs

- **[Risk] 多段折线与量标叠层坐标** → 量标仍按非零点布局。  
- **[Trade-off] 返回入 Row 后 Stack 遮罩/飞入** → 飞入 `GlobalKey` 仍在事件 logo，不受影响。

## Migration Plan

按 chrome → 触控 → 轴线 → 折线 → 时间轴顺序改；回滚为还原上述文件。

## Open Questions

- 无。
