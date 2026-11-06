## 1. Island 系统 timer

- [x] 1.1 将 `IslandTimingHmsText` 改为（或替换为）与锁屏一致的 `Text(timerInterval: start...end, countsDown: false, showsHours: true)`；上界约 99h；去掉 TimelineView / `formatHms` 主路径
- [x] 1.2 compact trailing 仍包在 `CompactIslandTimeSlot`；expanded trailing 使用同一系统 timer
- [x] 1.3 更新 `app/ios/PangbaoWidget/LIVE_ACTIVITY.md`：Island 时间位改为系统 timerInterval（不再写死自算 hh:mm:ss）

## 2. 验收

- [ ] 2.1 真机 Timing LA：锁屏与灵动岛已计时均走动；compact 仍为胶囊
- [x] 2.2 不新建 `**/test/**`
