## Why

预计临近（Imminent）Live Activity 在锁屏与灵动岛仍展示倒计时／「预计m分钟后」，与产品意图不符：预计事件只需提示「有事将至」，不需要时间维读数。过期态本就无时间文案；现要求未过期也一律不展示时间维，并收紧 compact 右侧空槽。

## What Changes

- Imminent 锁屏下层右侧 MUST NOT 展示任何时间维文案（含「预计m分钟后」、数字倒计时、「已过时」）；未过期与过期一致，仅品牌名 + 事件图 + 标题。
- Imminent Dynamic Island（compact trailing、expanded trailing）MUST NOT 展示倒计时或其它时间维文案；废除「Island 固定 hh:mm:ss」对 Imminent 的要求。
- compact MUST 收掉右侧时间占位槽（不再用隐藏 `"00:00:00"` 报宽）；岛宽由 leading（logo + 短名）与 minimal 决定。
- 标题语义保留：`lockTitle` 空兜底「事件即将发生」／Island「即将发生」等状态语气可留；MUST NOT 视为时间维数字。
- Timing Live Activity 行为不变；推送 Attributes（含 `nextAt`）可保留供对端起停，UI 可不读。
- 更新 `LIVE_ACTIVITY.md`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：锁屏与 Island 全表面去掉时间维；compact 无右槽；保留「即将发生」类标题。

## Impact

- 代码：`app/ios/PangbaoWidget/PredictLiveActivityViews.swift`（Imminent 锁屏 trailing、Island trailing/compactTrailing、可删 `LockImminentMinuteText` / `IslandImminentHmsText` / `imminentRemainingChinese`）、`LIVE_ACTIVITY.md`。
- 推送／Flutter／Android：无契约字段变更要求。
- 依赖前序 UI：`live-activity-lock-polish`（双层无圆标、事件图约 37pt）布局骨架保留。
