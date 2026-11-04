## Context

Imminent 锁屏经 `LockScreenTwoTier` 注入 `LockImminentMinuteText`（「预计m分钟后」）；Island expanded/compact trailing 使用 `IslandImminentHmsText`（`hh:mm:ss`），compact 外包 `CompactIslandTimeSlot`。产品现要求预计事件全表面无时间维；标题「即将发生」类状态语气保留；compact 收掉右槽以免空白胶囊。

## Goals / Non-Goals

**Goals:**

- 锁屏 Imminent trailing 恒空（`EmptyView` 或等价）。
- Island expanded trailing、compact trailing 无倒计时／无时间文案；compact 不再包 `CompactIslandTimeSlot`。
- 删除仅服务于 Imminent 时间维的 helper（若无其它引用）。
- `lockTitle`／Island 中心标题兜底不变。
- 文档与规格对齐。

**Non-Goals:**

- 不改 Timing 锁屏系统 timer 或 Island Timing `hh:mm:ss`。
- 不改推送字段、`nextAt` 解码、对端 end 策略、本地 `Activity.request`。
- 不改双层布局尺度（胖宝字、37pt 事件图）——沿用 polish。
- 不把「即将发生」改成其它产品名。

## Decisions

1. **时间维定义：数字／「预计…分钟」／「已过时」类读数；不含标题状态词。**  
   「事件即将发生」留在 `lockTitle` empty 兜底。

2. **锁屏：`LockScreenTwoTier` trailing 传空视图。**  
   不再调用 `LockImminentMinuteText`；可不再读取 `nextUnix` 仅供 UI（Attributes 仍解码）。  
   *备选：过期才空、未过期仍显示 — 否决（产品要求全去）。*

3. **Island：trailing 用 `EmptyView`；compactTrailing 直接空，不套占位槽。**  
   Timing 仍用 `CompactIslandTimeSlot`；该组件保留。  
   *备选：compactTrailing 仍套空槽 — 否决（会留右空白）。*

4. **清理。**  
   若 `IslandImminentHmsText`、`LockImminentMinuteText`、`imminentRemainingChinese` 仅 Imminent 使用则删除；`formatHms` 若 Timing Island 仍用则保留。

5. **规格。**  
   MODIFIED 锁屏主需求；REMOVED「Imminent Dynamic Island time SHALL always use hh:mm:ss」；ADDED compact／Island 无时间维与无右槽场景。

## Risks / Trade-offs

- [用户无法从 LA 读出「还有多久」] → 产品明确只要提醒；详情进 App。  
- [compact 变窄后与 Timing 并存时不对称] → 可接受；Imminent 无右读数。  
- [对端仍推 nextAt 但 UI 不用] → 无害；便于日后恢复或服务端调度。

## Migration Plan

1. 发版 App + Extension 后生效。  
2. 回滚：恢复 MinuteText / HmsText 与 compact 占位槽。

## Open Questions

- 无（探索已定：B 全表面去时间、标题可留、compact 收右槽）。
