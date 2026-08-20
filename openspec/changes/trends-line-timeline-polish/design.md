## Context

依赖 `trends-dual-chart-ux` / `trends-dual-chart-polish`。`nonZeroSegments` 把连续非零拆段，稀疏数据下大量单点段无法连线。时间轴画家用白半透明轴与偏深四段底。

## Goals / Non-Goals

**Goals:**

- 非零点单折线连通。
- 折线选中：竖线 + 具体时间。
- 时间轴：事件色轴、浅背景、标签先下后上交替。

**Non-Goals:**

- 改近 N 日柱图、范围预设、piece 拉取。
- 像素级碰撞检测（仅序号奇偶交替）。

## Decisions

1. **连线**  
   `spots = hourly.where(v>0).map(FlSpot)` 排序后单一 `LineChartBarData`；删除按零拆段。

2. **选中**  
   Stateful：`LineTouchData` 启用；`extraLinesData` 画选中 `x` 的竖线（accent）；tooltip/`showingTooltipIndicators` 或触点旁文案显示 `HH:00`（小时桶）+ 量。默认：有数据时选中最后一个非零点（便于进页即见）。

3. **时间轴轴色**  
   底轴与刻度短线用 `accentColor`（可 alpha≈0.75）。

4. **背景变浅**  
   段底 lerp 更靠白、alpha≈0.12～0.16。

5. **标签交替**  
   按 `t` 排序；`i%2==0` 点下细线+文案，奇数点上；细线长度保持短段；尽量仍在带内。

## Risks / Trade-offs

- **[Risk] 跨大空隙斜线可能被误读为中间有值** → 仅连非零点是产品接受的预测页同款语义。  
- **[Trade-off] 奇偶交替非距离阈值** → 极密三点仍可能部分重叠，可接受。

## Migration Plan

改 `trend_day_detail_chart.dart`；回滚还原该文件。

## Open Questions

- 无（默认选中末个非零点）。
