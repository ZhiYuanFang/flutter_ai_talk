## Context

`_yAxisStep` 现用 `span / 4` 以支持 ≤5 刻度。产品冻结为**固定 3** 个时刻标签。

## Goals / Non-Goals

**Goals:**

- Y 轴时刻标签固定为 **3** 个（底、中、顶语义）。
- 更新 spec，废止「≤5」表述。

**Non-Goals:**

- 不改折线取点、实虚线、触点浮层。
- 不新建测试。

## Decisions

1. **固定 3**  
   `raw = span / 2`，再向上 snap 到 15/30/60…；`SideTitles.interval = step`，使轴上呈现 3 个主刻度（`minY`、`minY+step`、`minY+2*step`≈`maxY`）。  
   若 snap 导致与 `maxY` 略有偏差，仍以 interval 对齐的三档为准，或微调 `maxY` 使 `minY + 2*step` 贴近原上限（实现选更简单且视觉稳定者）。

2. **相对 ≤3**  
   产品明确「固定 3」，不以「更少」为常态；仅在 `span≈0` 退化时允许少于 3（单点/零跨度防护）。

## Risks / Trade-offs

- **[Trade-off] snap 后三档不完全贴齐原 maxY** → 可轻微扩展 maxY 到 `minY+2*step` 以整齐。

## Migration Plan

1. 改 `_yAxisStep` 为 `/2`，必要时对齐 maxY。  
2. 更新/替换 Y 轴 Requirement。  
3. 热重载确认三档标签。

## Open Questions

- 无。
