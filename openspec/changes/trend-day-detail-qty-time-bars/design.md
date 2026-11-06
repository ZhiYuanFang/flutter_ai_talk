## Context

`TrendDayDetailChart`：`one`→时间轴；`number`/`time`→`_DayLineChartInteractive`（先 `_fillHourly*` 再非零折点）。喂养按日 Sheet 与趋势某日详图共用。产品锁定：**组件级 B**；量/时改柱；**有数据才出柱**；X 不硬定 24h；**柱上时间到分**。

## Goals / Non-Goals

**Goals:**

- 量/时：稀疏柱图；每柱对应一条有效样本（`value > 0` 的 raw 点/记录）。
- 柱标（柱顶或柱旁）为该点 `t` 的本地 **`HH:mm`**。
- X：按样本序或时刻比例排布，不强制 0–23 共 24 格。
- 计次时间轴不变；量值语义不变（时→小时，量→数值）。

**Non-Goals:**

- 改近 N 日柱图、今昨双折线 Sheet。
- 计次改柱。
- 新增 HTTP。

## Decisions

1. **一样本一柱**  
   过滤 `rawForDay` 中有效点（与现「非零」语义一致），按 `t` 升序；每点一根柱，高度=`value`。  
   备选：按小时聚合并仅非空小时出柱——与「精确到分」冲突更大，放弃。

2. **时间文案**  
   柱顶（或紧贴柱）显示 `DateFormat('HH:mm')`（本地）；同一分钟多条 MAY 并排/微偏，不得丢标。

3. **X 轴**  
   类目轴（柱索引）或按当日分钟比例映射；刻度 MAY 稀疏，MUST NOT 要求固定 24 个整点标签。

4. **空态**  
   无样本：空坐标框（Y 默认量级可保留约 0–10）；MUST NOT 24 零柱、MUST NOT 幽灵折线。

5. **实现落点**  
   在 `TrendDayDetailChart` 用 `_DaySparseBarChart`（或等价）替换 `_DayLineChartInteractive` 分支；玻璃/accent 对齐趋势柱图族。

6. **规格**  
   同步改 `trends-center-event-charts` 与 `home-per-day-summary-sticky` 中「折线」验收语。

## Risks / Trade-offs

- [样本极多柱过密] → 可横向滚动或变窄柱；首版接受挤，跟进再加滚动。  
- [与「小时桶」旧文案] → 明确改为样本柱，避免实现仍 fillHourly。  
- [趋势+喂养同改] → 产品要的 B；一次验收两处。

## Migration Plan

1. 实现稀疏柱分支 → 更新空态 → 改 OpenSpec 已写入本 change。  
2. 手工：量/时有数据见柱+分；无空小时柱；计次仍轴；喂养 Sheet 与趋势某日一致。  
3. 回滚：恢复折线分支。

## Open Questions

- （已定）B；有数据才柱；X 非硬 24；柱标到分；一样本一柱。
