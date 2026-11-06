## Context

锁屏 Timing 经 `live-activity-lock-polish` 回到 `Text(timerInterval:)` 会动；Island 仍用 `IslandTimingHmsText`（`TimelineView` + `formatHms`），真机灵动岛计时常冻住。`live-activity-island-compact-width` 本已要求 compact 槽内画 `timerInterval` + 短占位，实现却偏到自算秒。产品要求 Island 对齐系统 timer。

## Goals / Non-Goals

**Goals:**

- Island compact / expanded 已计时改用系统 `timerInterval`（与锁屏同源语义）。
- compact 保留 `CompactIslandTimeSlot` 短占位，防撑宽。
- 区间有限上界（~99h），不用 `distantFuture`。
- 更新 `LIVE_ACTIVITY.md`。

**Non-Goals:**

- 不改锁屏布局、Imminent Island、Push/Attributes、Flutter register。
- 不强制 Island 继续零填充自算 `hh:mm:ss`。
- 不靠高频 push ContentState 刷秒。

## Decisions

1. **复用锁屏 timer 语义**  
   将 `IslandTimingHmsText` 改为（或替换为）与 `LockTimingElapsedText` 相同的 `Text(timerInterval: start...end, countsDown: false, showsHours: true)`；`end = start + ~99h`。可抽共享 helper，或 Island 直接调用同一私有组件。  
   备选：保留 TimelineView — 否决（已证不可靠）。

2. **compact 宽度隔离不变**  
   `compactTrailing` 仍包在 `CompactIslandTimeSlot` 内：隐藏 `"00:00:00"` 报宽，overlay 画系统 timer（`minimumScaleFactor` 可留）。expanded trailing 可直接放 timer（无占位槽）。

3. **格式接受系统样式**  
   不再产品侧 `formatHms`；文档与规格改为「系统 timer，可含秒」。

## Risks / Trade-offs

- [系统格式 ≠ hh:mm:ss] → 产品已接受「会动」优先。  
- [timerInterval 再撑宽] → 必须留在 CompactIslandTimeSlot。  
- [startTime 错误仍 00:00] → 与锁屏同源；属推送字段问题，另查。

## Migration Plan

1. 改 `PredictLiveActivityViews.swift` Island 时间位 → 更新 `LIVE_ACTIVITY.md`。  
2. 真机：Timing LA — 锁屏与灵动岛已计时均走动；compact 仍为胶囊。  
3. 回滚：恢复 `IslandTimingHmsText` TimelineView（会再冻）。

## Open Questions

- （已定）Island 用系统 timer；放弃 Island 强制自算 hh:mm:ss。
