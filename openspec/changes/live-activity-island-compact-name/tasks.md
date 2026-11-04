## 1. compact 短名

- [x] 1.1 在 `PredictLiveActivityViews.swift` 增加按 `Character` 截取最多 3 字、trim 空则空串的辅助函数（无省略号）
- [x] 1.2 Imminent `compactLeading`：logo + 三字（来自 `title`，ContentState 优先）；空则仅 logo；不得用「即将发生」模板
- [x] 1.3 Timing `compactLeading`：logo + 三字（来自 `eventName`，ContentState 优先）；空则仅 logo；不得用「计时中」模板

## 2. 验收

- [x] 2.1 结构核对：锁屏 / expanded 全名与 `compactTrailing` 占位槽未改；compact 不放入未截断全名
- [x] 2.2 本变更仅 iOS Extension Swift，不新建 `**/test/**`，不改 Android
