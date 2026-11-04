## Why

Imminent / Timing 的 compact 灵动岛会被系统计时 `Text(timerInterval:)` 撑到接近满屏宽：该 Text 按区间理论上最长数字预留固有宽度，compact 岛又按子视图固有宽度变长，两边互抬。锁屏横条满宽与长按 expanded 宽胶囊是系统形态，不在本变更范围。`live-activity-lock-ui` 只规定锁屏「左图 + 中标题 + 右大字」，未约束 compact 岛宽。

## What Changes

- **Imminent / Timing compact 灵动岛**：`compactTrailing` 的倒计时 / 已计时 MUST 由固定短占位（如隐藏 `"00:00:00"`）向岛报告固有宽度，真计时叠在该槽内；岛 MUST 保持胶囊，MUST NOT 被拉到接近满屏宽。
- **Timing 计时区间**：compact 所用 `timerInterval` MUST NOT 再接到 `Date.distantFuture`；改用有上界的区间（防御，主因仍是占位箍宽）。
- **「已过时」**：仍为普通短文案，MUST NOT 使用会撑宽的 `timerInterval`。
- **非目标**：不改锁屏 `HStack` 大字靠右、不改 expanded / minimal、不改 Attributes / 推送 / token 注册、不本地 `Activity.request`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：补充 compact 灵动岛宽度约束；锁屏与 expanded 布局保持 `live-activity-lock-ui` 的左图 / 中标题 / 右倒计时。
- `predict-timing-live-activity`：同上，并禁止 Timing compact 计时区间接到无限远未来。

> 说明：上述 capability 已在未归档 change（`predict-ios-live-activity`、`live-activity-lock-ui` 等）中落地，尚未并入 `v2.1.4` 基线；本变更对其 Requirement 做 MODIFIED delta。

## Impact

- iOS：仅 `PredictLiveActivityViews.swift`（compactTrailing 包装；Timing 区间上界）
- Flutter / Android / Web / 对端 Go：无
- 契约：不改 `LIVE_ACTIVITY.md` 推送字段
