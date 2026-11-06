## Why

Timing Live Activity 锁屏已用系统 `Text(timerInterval:)` 会动，灵动岛仍用 `TimelineView` 自算 `hh:mm:ss`，真机常卡住。产品要求 Island 也改回系统 timer。

## What Changes

- Timing Dynamic Island（compact trailing + expanded trailing）MUST 使用 SwiftUI `Text(timerInterval:)`（或等价 ActivityKit 系统计时 Text），`countsDown: false`，自 `startTime`（unix 秒）起已计时。
- compact MUST 继续经 `CompactIslandTimeSlot`（或等价短占位）报告固有宽度，MUST NOT 再被 timer 测量撑满屏。
- timer 区间 MUST 有有限上界（约自 start 起 99 小时），MUST NOT 使用 `Date.distantFuture`。
- **BREAKING（相对现实现/文档）**：Island 不再保证零填充自算 `hh:mm:ss`；格式跟随系统 timer（可含秒）。
- 锁屏 Timing 路径本变更不改（已是 timerInterval）。
- 更新 `LIVE_ACTIVITY.md` Island 时间位说明。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-timing-live-activity`：Island 已计时改为系统 `timerInterval`；去掉对 Island 自算 `hh:mm:ss`/TimelineView 的依赖。

## Impact

- 代码：`app/ios/PangbaoWidget/PredictLiveActivityViews.swift`（`IslandTimingHmsText` → 系统 timer；compact 仍走 `CompactIslandTimeSlot`）。
- 文档：`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`。
- 无 Flutter Dart / HTTP / Go 变更。
