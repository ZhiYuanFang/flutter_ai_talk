## Why

灵动岛 compact 事件名被硬截为最多 3 个 Character，expanded 中心标题又被 `lineLimit(1|2)` 压行，长事件名读不全。产品要求 Imminent / Timing 两侧一并放开：不再做字数截断，并放宽 expanded 行数限制。

## What Changes

- **BREAKING（相对既有 compact 三字规格）**：Imminent / Timing 的 `compactLeading` 事件名 MUST 展示完整 trim 后名称（来自 `title` / `eventName`），MUST NOT 再 `prefix(3)` 硬截；空名仍仅 logo；仍 MUST NOT 用「即将发生」「计时中」等锁屏模板句充 compact 名。
- expanded 中心标题：Imminent / Timing MUST 去掉或显著放宽既有 `lineLimit(1|2)`，不得再以产品侧短行数限制标题长度（系统布局仍可自然换行/裁切）。
- Timing `compactTrailing` 的 `CompactIslandTimeSlot` 行为保留；Imminent compact 无右槽（沿用 `live-activity-imminent-no-time`）。
- 锁屏双层标题本变更不改。
- 更新 `LIVE_ACTIVITY.md`；规格上废止「最多三字」Requirement，改为全名 Requirement。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：compact 全名；expanded 放宽 lineLimit。
- `predict-timing-live-activity`：compact 全名；expanded 放宽 lineLimit。

## Impact

- 代码：`PredictLiveActivityViews.swift`（`compactIslandName`、`CompactIslandLeading`、expanded center `lineLimit`）。
- 风险：Timing compact 左全名 + 右 timer 槽可能再次变宽；验收需真机看长名。
- 推送／Android：无契约字段变更。
