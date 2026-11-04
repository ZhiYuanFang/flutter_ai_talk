## 1. compact 宽度槽

- [x] 1.1 在 `PredictLiveActivityViews.swift` 增加 compact 专用槽（隐藏 `"00:00:00"` + overlay 真内容，`minimumScaleFactor`、单行）；仅供 Island compact 使用
- [x] 1.2 Imminent / Timing 的 `compactTrailing` 改为经该槽包裹现有倒计时 / 已计时 View；不改锁屏与 expanded 调用点

## 2. Timing 区间

- [x] 2.1 `TimingElapsedText`（或 compact 专用路径）将 `timerInterval` 上界从 `Date.distantFuture` 改为自 `startTime` 起约 99 小时；锁屏若共用该 helper，不得加 `.fixedSize()`

## 3. 验收

- [x] 3.1 目视：Imminent / Timing compact 岛为胶囊，倒计时 / 已计时 /「已过时」仍可见；锁屏满宽大字与 expanded 形态未改
- [x] 3.2 本变更仅 iOS Extension Swift，不新建 `**/test/**`，不改 Android
