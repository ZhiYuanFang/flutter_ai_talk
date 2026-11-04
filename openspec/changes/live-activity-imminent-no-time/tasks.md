## 1. Imminent 去时间维 UI

- [x] 1.1 锁屏 `PredictImminentLiveActivity` content：`LockScreenTwoTier` trailing 改为空视图；去掉对 `LockImminentMinuteText` / `nextUnix` 的 UI 依赖
- [x] 1.2 Island expanded trailing、compactTrailing 去掉倒计时；compactTrailing MUST NOT 再包 `CompactIslandTimeSlot`；保留 leading 短名与中心「即将发生」类标题
- [x] 1.3 删除仅 Imminent 使用的 `LockImminentMinuteText` / `IslandImminentHmsText` / `imminentRemainingChinese`（`formatHms` 若 Timing 仍用则保留）

## 2. 文档与验收

- [x] 2.1 更新 `LIVE_ACTIVITY.md`：Imminent 锁屏与 Island 无时间维；compact 无右槽；标题「即将发生」可留；Timing 说明不变
- [x] 2.2 真机/模拟器目视：Imminent 锁屏与 Island 无「预计…」/倒计时、compact 无右侧空 timer 槽；Timing 锁屏 timer 与 Island `hh:mm:ss` 无回归
