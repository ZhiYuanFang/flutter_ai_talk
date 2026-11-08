## Why

统一锁屏 Live Activity 在条目列表之上额外画了一行居中「胖宝」，与系统 LA 外框已有的 App 身份重复，并占用纵向高度。多条 `items` 混排时高度更紧，需要去掉内容区 App 名顶栏以减占位。

## What Changes

- **锁屏去品牌行**：统一 `BabyLiveActivityAttributes` 锁屏内容 **不得** 再展示顶栏「胖宝」（或等价 App 名）；仅按 `items` 纵向堆叠既有 Imminent/Timing 行。
- **文档**：`LIVE_ACTIVITY.md` 去掉「顶栏胖宝居中主题色」描述。
- **非目标**：不改 Dynamic Island、行内事件 logo/标题样式、register/ack、Go 消息体；不改桌面小组件文案。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `unified-live-activity`：锁屏从「居中主题色品牌行 + 动态条目」改为「仅动态条目、无 App 名顶栏」（相对 `unify-live-activity-list` 中该能力需求的修正）。

## Impact

- iOS：`PredictLiveActivityViews`（锁屏 VStack）、可选清理仅服务顶栏的 `themePrimaryHex` / `laThemeBrandColor`。
- 文档：`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`。
- 对端：无 Go 变更。
- 基线/并行：覆盖尚在进行的 `unify-live-activity-list` 顶栏产品要求；合入顺序上本变更应在统一列表 UI 之后或一并验收。
