## 1. 锁屏双层共用布局

- [x] 1.1 `LockScreenTwoTier` 上层去掉 `AppBrandMark`，仅保留「胖宝」文字（事件提亮色）
- [x] 1.2 下层 `eventLogo` size 由 56 改为约 37（2/3）；若 `AppBrandMark` 无引用则删除其类型定义

## 2. Timing 锁屏标题与系统 timer

- [x] 2.1 `timingLockTitle`：有名仅事件名，空名短兜底「事件」；MUST NOT 拼「计时中」
- [x] 2.2 Timing 锁屏 trailing 改用 `Text(timerInterval:)`（`countsDown: false`，建议 `showsHours: true`），区间自 `startTime` 起约 99 小时有限上界；字体/颜色仍走 TwoTier trailing 样式
- [x] 2.3 移除锁屏路径对 `LockTimingMinuteText` / `timingElapsedChinese` 的依赖；删除无用 helper，避免回归中文「已过去」

## 3. 文档与验收

- [x] 3.1 更新 `LIVE_ACTIVITY.md`：锁屏上层无圆标、Timing 系统 timer（可带秒）、标题无「计时中」、事件图约 37pt；Imminent 时间文案说明保持中文到分钟
- [x] 3.2 真机/模拟器目视：Timing 锁屏时间会动、无「已过去」/「计时中」、上层无 App 圆标、事件图明显小于原 56；Imminent 仍为「预计m分钟后」且布局同步；Island 行为无回归
