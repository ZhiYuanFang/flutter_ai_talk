## Context

`home-per-day-summary-sticky` 已将主页日分块键改为 `historyHomeDayKeyInstant`（`startTime`），但刻意保留 `historyHomeDisplayInstant` 对已结束计时取 `endTime`，供左列 `HH:mm`、日内排序与相对 ago 共用。结果：跨夜睡眠归「昨天」，左列却显示今早醒来钟点。产品锁定方案 **B**：只改左列文案为开始时刻，ago 仍相对 end。

## Goals / Non-Goals

**Goals:**

- 左列 `HH:mm` 与日键同源：优先 `startTime`，缺失回退与 `historyHomeDayKeyInstant` 相同。
- 相对 ago、「各事件最新」选取、日内 `sort` 继续走既有 `historyHomeDisplayInstant`（已结束 `eventNumber==0` 仍为 end）。
- 拆出独立「左列时钟」helper，避免误改 display instant 波及 ago。

**Non-Goals:**

- 不把 `historyHomeDisplayInstant` 全局改为 start（方案 A）。
- 不改预测 `occurrenceInstant` / 分桶。
- 不改日汇总聚合、Sheet、HTTP。
- 不新建测试文件。

## Decisions

1. **新增左列时钟 helper（建议名 `historyHomeClockInstant`）**  
   实现可直接委托 `historyHomeDayKeyInstant`（同为 start → createdAt），或显式写同等规则。  
   `historyHomeRowDisplay` 的 `timeLabel` MUST 用该 helper 格式化 `HH:mm`。  
   **不得**改 `historyHomeDisplayInstant` 本体。  
   备选：就地改 display instant 再给 ago 另开 end helper——与「ago 仍相对 end」等价但更易漏改调用点；放弃。

2. **ago / 排序调用点不动**  
   `home_history_scroll.dart`（ago 文案、最新判定）、`buildHomeHistoryDayGroups` 日内 sort 继续 `historyHomeDisplayInstant`。  
   左列与排序锚可短暂不一致（同日多条时 HH:mm 非严格升序）；接受，因 B 明确只改文案。

3. **适用范围**  
   所有主页时间轴行左列统一用时钟 helper（含 `n==1` / `n>1`）；点事件 start≈end，观感基本不变；计时跨夜场景是主收益。

4. **旧 plain / spans**  
   `historyLineSpans` / `historyLinePlainText` 非主页 tile 主路径；本变更可不改，除非仍有主页消费。以 `historyHomeRowDisplay` 为准。

## Risks / Trade-offs

- [左列与排序不一致] → 产品已选 B；若后续嫌乱再开「排序也跟 start」小变更。  
- [误改 display instant] → code review / 任务明确「只动 timeLabel」。  
- [ago 文案与左列钟点心理不一致] → 有意保留（醒后「刚刚」）。

## Migration Plan

1. 加 `historyHomeClockInstant`（或复用 day key）→ `historyHomeRowDisplay.timeLabel` 改用。  
2. 确认 scroll / sort / ago 仍调 display instant。  
3. 手工：跨夜已结束计时 — 左列=开始 HH:mm、日块=开始日、ago≈相对结束。  
4. 回滚：timeLabel 改回 display instant。

## Open Questions

- （已定）B：左列 start，ago 仍 end。
