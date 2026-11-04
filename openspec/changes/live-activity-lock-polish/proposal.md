## Why

锁屏 Timing Live Activity 在 `live-activity-lock-two-tier` 改为自算中文「已过去…」+ `TimelineView` 后，系统不再驱动时间位刷新，真机常表现为计时卡住；同时产品希望去掉「已过去」「…计时中」、去掉上层 App 圆标，并缩小事件图。需要在保留双层锁屏骨架的前提下，把 Timing 时间位改回会动的系统 timer（允许带秒），并收紧文案与尺度。

## What Changes

- Timing 锁屏右侧时间位改回系统 `Text(timerInterval:)`（已计时、`countsDown: false`），允许带秒；不再使用「已过去h时m分钟」中文与「不足 1 分钟按 1」规则。
- Timing 锁屏主标题去掉全部「计时中」后缀：有事件名则只显示事件名；空名兜底为「事件」（或等价短兜底，不得再拼「事件计时中」）。
- 锁屏双层上层：去掉圆形 App brand logo（`AppBrandMark`），保留「胖宝」文字行。
- 锁屏下层事件 logo 由约 56pt 缩至约 2/3（约 37pt）；Imminent / Timing 共用 `LockScreenTwoTier` 一并生效。
- Imminent 锁屏时间文案（「预计m分钟后」）与 Island `hh:mm:ss` 路径本变更不改产品语义（除共用布局尺度/品牌行）。
- 更新 `LIVE_ACTIVITY.md` 与既有 Timing/Imminent 锁屏规格 delta，使之与上述 UI 一致。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-timing-live-activity`：锁屏标题去「计时中」；时间位改系统 timer（可带秒）；上层无 App 圆标；事件图约 37pt。
- `predict-imminent-live-activity`：锁屏共用双层布局——上层无 App 圆标、下层事件图约 37pt（时间文案语义不变）。

## Impact

- 代码：`app/ios/PangbaoWidget/PredictLiveActivityViews.swift`（`LockScreenTwoTier`、`timingLockTitle`、`LockTimingMinuteText` / `timingElapsedChinese`）、`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`。
- 推送 Attributes / App Group / Flutter Dart：**无**契约字段变更。
- Android：不在范围。
- 真机验收：锁屏 Timing 时间位应持续跳动（秒级或系统 AOD 降级态）；标题无「计时中」；上层无圆标；事件图明显小于现 56pt。
