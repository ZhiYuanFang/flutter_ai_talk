## Why

compact 灵动岛目前只有左侧 logo 与右侧计时，日常不长按时看不到事件名。expanded / 锁屏已有全名。产品需要 compact 一眼能辨认是哪件事件，同时不得破坏 `live-activity-island-compact-width` 已箍住的胶囊宽度。

## What Changes

- **Imminent / Timing compactLeading**：在 18pt 事件 logo 右侧展示事件名，最多 **3 个 Character**（按字截取，无省略号）。空名则只保留 logo。
- **名字来源**：从事件名字段截取，**不是**锁屏长句模板（「即将发生」「××计时中」）。Timing 用 `eventName`（ContentState 优先，否则 Attributes）。Imminent 契约无 `eventName` 字段，用等价的 `title`（同一套 ContentState → Attributes 回退）。
- **compactTrailing / 岛宽**：保持现有 `CompactIslandTimeSlot`；本变更 MUST NOT 把未截断全名丢进 compact。
- **非目标**：不改锁屏 / expanded 全名、不改 minimal、不改推送字段、不写 `laEventVisuals.name`、不本地 `Activity.request`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：compactLeading 增加最多三字事件名（来自 `title`）。
- `predict-timing-live-activity`：compactLeading 增加最多三字事件名（来自 `eventName`）。

> 说明：上述 capability 已在未归档 change（`predict-ios-live-activity`、`live-activity-lock-ui`、`live-activity-island-compact-width` 等）中落地，尚未并入 `v2.1.4` 基线；本变更对其 Requirement 做 ADDED delta。

## Impact

- iOS：`PredictLiveActivityViews.swift`（compactLeading）
- Flutter / Android / Web / 对端 Go：无
- 契约：不改 `LIVE_ACTIVITY.md` 字段；Imminent 仍用 `title` 作为事件名
