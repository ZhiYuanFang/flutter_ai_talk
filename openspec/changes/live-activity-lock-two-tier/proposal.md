## Why

锁屏 Live Activity 仍是单行「事件图 + 标题 + 数字秒级计时」：品牌辨识弱、秒级数字在未解锁约 1 分钟刷新的锁屏上意义不大，且 Imminent 过期「已过时」噪音多余。产品需要双层锁屏（上品牌、下事件+中文到分钟）与灵动岛固定 `hh:mm:ss`。

## What Changes

- **锁屏双层布局（Imminent / Timing）**：上层窄行圆形 App logo + App 名「胖宝」（文案色随事件色）；下层宽行事件 logo + 既有标题语义 + 右侧时间文案；下层图标与文案尺度相对现状约放大一倍；时间靠右。
- **锁屏时间文案（中文到分钟）**：Timing 为「已过去h时m分钟」（`h=0` 省略时 →「已过去m分钟」）；Imminent 为「预计m分钟后」（总分钟，如 90）；不足 1 分钟按 1 分钟计；Imminent 已过期时右侧 **不** 展示「已过时」或其它时间维文案。
- **标题语义不变**：Timing 仍用「{事件名}计时中」/「事件计时中」；Imminent 仍用既有 `lockTitle` 回退。
- **灵动岛时间格式**：compact / expanded 时间位 MUST 始终为 `hh:mm:ss`（两位时），不得在不足 1 小时时收成仅 `mm:ss`；compact 宽度占位与三字名约束保持既有 change。
- **非目标**：不改推送字段 / token 注册 / 本地 `Activity.request`；不把锁屏中文长句塞进 compact trailing；不改 Android。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：锁屏改为双层；时间改为「预计m分钟后」；过期不展示时间维文案；Island 时间位固定 `hh:mm:ss`。
- `predict-timing-live-activity`：锁屏改为双层；时间改为「已过去…」中文到分钟；Island 时间位固定 `hh:mm:ss`；标题语义保持「…计时中」。

> 说明：上述 capability 已在未归档 change（`predict-ios-live-activity`、`live-activity-lock-ui`、`live-activity-island-compact-width`、`live-activity-island-compact-name` 等）中落地，尚未并入 `v2.1.4` 基线；本变更对其 Requirement 做 MODIFIED / ADDED delta。

## Impact

- iOS：`PredictLiveActivityViews.swift`（锁屏布局与时间文案、Island `hh:mm:ss`）、必要时 `WidgetVisualHelpers.swift` / `LIVE_ACTIVITY.md` 展示说明
- Flutter / Android / Web / 对端 Go：无（不改推送契约）
