## Context

智能预测事件卡折线（`smart_prediction_screen.dart` 内 `_DailyNearTodChart`）底部刻度当前对每个自然日索引渲染 `${month}/${day}`。网格窗为今天−2…今天（3 日），列表窗为今天−6…今天（7 日）。`prediction-layout-list-grid` 已要求网格 X 为前天/昨天/今天，但实现未换文案。

## Goals / Non-Goals

**Goals:**

- 按「距今天的本地自然日差」输出 X 文案：0→今天，1→昨天，2→前天，其余→`M/d`。
- 列表保持 7 日窗与 Y 轴；网格保持 3 日窗与无 Y 轴——仅改标签。

**Non-Goals:**

- 不改取点规则（TOD-near / 今日 nextAt）、虚线样式、触摸 tooltip。
- 不改 tip、推演开关、小组件、range 拉取深度。
- 不新建测试文件。

## Decisions

1. **单一标签函数，两布局共用**  
   在图表 `getTitlesWidget`（或同文件小 helper）用 `DateTime` 日差分支；网格因窗内全是 0/1/2，自动全相对日；列表自动「前 4 日日期 + 后 3 日相对日」。  
   **备选**：布局分支两套文案表——拒绝，易漂移。

2. **日差以本地日历日（去时分）计算**  
   与现有 `day0` / `DateUtils` 风格一致，避免跨午夜错标。

3. **字号/颜色沿用现有 bottomTitles**  
   「前天」两字略宽于 `8/6`，若溢出再微调 `fontSize`（实现时按需，不预扩 reservedSize 除非实测裁切）。

## Risks / Trade-offs

- [窄卡「前天」裁切] → 网格可略降字号或 `FittedBox`；优先保持现有 9sp。  
- [与 layout change 文案重复] → 本 change 用更精确的混排规则覆盖「一律相对日」误解；归档时以本 delta 为准细化。

## Migration Plan

- 纯客户端文案；热重载/重装即可。无需数据迁移。

## Open Questions

- （无）产品已确认列表前 4 天日期、后 3 天相对日；网格三日全相对日。
