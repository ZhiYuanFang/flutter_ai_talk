## Context

`_LookbackChart` 现用单条 `dashArray` 虚线、`leftTitles.interval: 60`（易超过 5 个标签）、无触点浮层。今日点规则已由 `prediction-chart-today-nextat` 固定。本 change 只改展示。

## Goals / Non-Goals

**Goals:**

- Y 轴时刻标签 **≤5**。
- 触点上方浮层显示该点 `HH:mm`。
- 历史段实线；仅连今日预测点的最后一段虚线。

**Non-Goals:**

- 不改取点算法 / `nextAt` / range 历史。
- 不改折线窗外的其它预测页 UI。
- 不新建测试文件。

## Decisions

1. **Y 轴 ≤5**  
   在 `minY/maxY` 上计算 `step`，使刻度数 ≤5（典型 `span/4` 后 snap 到 15/30/60 分钟）。`SideTitles.interval` 与水平网格共用该 step；`getTitlesWidget` 只渲染对齐刻度。

2. **触点浮层**  
   fl_chart `lineTouchData` + tooltip：文案为触点对应 `DateTime` 的 `HH:mm`，优先显示在点上方。

3. **双 LineBar**  
   - Bar A：所有非今日点（按 x 排序），`dashArray: null` 实线。  
   - Bar B：若存在今日点且存在至少一个过去点，则为 `[lastPast, todayNextAt]`，`dashArray` 虚线；两点共用衔接处圆点。  
   - 无今日点：仅 Bar A。仅今日点：可只画点（Bar 单点）。

4. **与今日点规则**  
   今日点仍仅来自同日 `nextAt`；本 change 不修改 `dailyPointsNearAnchorTod`。

## Risks / Trade-offs

- **[Risk] 双 bar 衔接点重复绘制** → 可接受；或 Bar A 不含末点、Bar B 含两点。  
- **[Trade-off] ≤5 而非固定 5** → 窄窗口刻度更少，更清晰。

## Migration Plan

1. 改 `_LookbackChart` 线型 / titles / touch。  
2. 手工：≤5 标签、触点浮层、实线+末段虚线。  

回滚：恢复单条全虚线与原 interval。

## Open Questions

- 无（Y 轴为 ≤5 已确认）。
