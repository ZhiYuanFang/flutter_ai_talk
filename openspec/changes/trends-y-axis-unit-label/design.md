## Context

趋势中心双图（近 N 日柱 + 某日详图）已有数值 Y 刻度与柱顶/折点量标，但缺少稳定的「单位」锚点。基线曾禁止「纵轴含义说明」长文案；本变更引入短固定单位标签，置于 Y 轴顶部。

## Goals / Non-Goals

**Goals:**

- 有数值 Y 的图在 Y 顶显示固定单位：`时长` / `unit|量` / `次`
- 计数 `EventDefinition.unit` trim 为空时 MUST 显示「量」
- 计次时间轴不增加 Y 单位文案

**Non-Goals:**

- 不改量值计算、Y 刻度算法、柱顶/折点量标格式
- 不强制改首页小时趋势 `yAxisHint` 文案（可后续对齐）
- 不新增 Android / 后端 / 自动化测试文件

## Decisions

1. **文案解析集中**  
   在 `trend_metric_format.dart`（或同级纯函数）提供 `trendYAxisUnitLabel(eventType, unit)`：
   - `time` → `时长`
   - `one` → `次`
   - `number`（及其它非 time/one）→ `unit.trim()`，空则 `量`

2. **放置位置**  
   单位文案 MUST 在**绘图区上方、Y 轴正上方**（对齐左侧 `reservedSize` 列宽），用 Column 独立一行而非 Stack 叠在图内；MUST NOT 与居中图表标题或顶档 Y 刻度数字重合。字号/颜色与次要轴标签一致。

3. **作用范围**  
   - MUST：`TrendNDayBarChart`（含计次柱图）
   - MUST：`TrendDayDetailChart` 折线态（`time`/`number`）
   - MUST NOT：计次时间轴（`_CountTimelinePainter` / timeline 分支）

4. **与旧约束关系**  
   MODIFIED「Bar chart axes and metric semantics / 不得额外展示纵轴含义说明」：禁止的是冗长「纵轴：小时 (h)」类说明；本变更的固定短单位（`时长`/`量`/`次`/自定义 unit）为允许且必需。

## Risks / Trade-offs

- [Y 区拥挤] → 短文案 + 小字号；必要时略增 leftTitles reservedSize。
- [与柱顶量标重复] → 可接受：顶标签是单位锚，柱顶/折点是具体数值。

## Migration Plan

无数据迁移。合并后热更即可。

## Open Questions

无（产品已确认空 unit →「量」；时间轴不加 Y 单位）。
