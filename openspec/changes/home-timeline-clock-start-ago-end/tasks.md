## 1. 左列时钟解耦

- [x] 1.1 在 `history_line_format.dart` 新增 `historyHomeClockInstant`（可委托 `historyHomeDayKeyInstant`）；**不得**改写 `historyHomeDisplayInstant` 的 end 语义
- [x] 1.2 `historyHomeRowDisplay.timeLabel` 改为基于 clock instant 的 `HH:mm`
- [x] 1.3 确认 `home_history_scroll` ago / 最新判定、`buildHomeHistoryDayGroups` 日内 sort 仍调用 `historyHomeDisplayInstant`

## 2. 验收

- [ ] 2.1 手工：跨夜已结束计时 — 日块=开始日、左列=开始 HH:mm、ago≈相对结束（醒后短间隔）
- [x] 2.2 不新建 `**/test/**`
