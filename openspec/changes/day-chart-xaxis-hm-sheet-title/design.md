## Context

`_DaySparseBarChart` 用柱顶 tooltip 钉 `HH:mm`，底轴关闭。喂养 Sheet 标题两行。产品要：时刻→X 轴；**量→柱顶**；Sheet 一行 `事件名 · 日`。

## Goals / Non-Goals

**Goals:**

- 量/时稀疏柱：`HH:mm` 在 **X 轴**；柱顶永久展示**量值**（非时刻）。
- 喂养按日 Sheet：居中一行 `{事件名} · {日文案}`。
- 组件级改动惠及趋势某日详图。

**Non-Goals:**

- 不改计次时间轴、近 N 日柱、趋势页标题行。
- 不改稀疏语义 / 日键 / HTTP。
- 密柱省略算法首版不做。

## Decisions

1. **分工：底=时、顶=量**  
   `bottomTitles` → `HH:mm`；柱顶用 `showingTooltipIndicators` + `formatTrendMetricLabel`（或等价）显示量；**不得**柱顶再显示时刻。  
   备选：touch 才出量——产品要常显柱顶量；放弃。

2. **底轴样式**  
   `glassBottomTitles` 或等价；`reservedSize` 容纳 `HH:mm`。`maxY` 略抬高给柱顶量标留空。

3. **Sheet 标题**  
   `Text.rich`：名大 + ` · ` + 日小；去掉独立日行。

## Risks / Trade-offs

- [顶量+底时都挤] → 首版接受；过挤再缩字/隔柱。  
- [量文案过长] → 跟 `formatTrendMetricLabel` 既有短串。

## Migration Plan

1. 底轴 HH:mm → 柱顶改量 → Sheet 标题。  
2. 手工：X 轴有分、柱顶有量；Sheet「名 · 日」。  
3. 回滚：恢复旧顶时刻 + 两行标题。

## Open Questions

- （已定）X=时、顶=量；Sheet 居中 `名 · 日`。
