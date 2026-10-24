## 1. 发生时刻

- [x] 1.1 `occurrenceInstant`：已结束计时改为 `startTime ?? createdAt`，不再用 `endTime`
- [x] 1.2 确认进行中 / one / number 路径仍为 start，且 `includeActive` 门闸不变

## 2. 回归核对

- [x] 2.1 间隔同桶投票与 duration expect / 进行中 ETA 仍按既有 start 锚点，互不串用 end 推 nextAt
- [x] 2.2 对照本 change 规格：已结束 time 取 start；上午 lastAt 可推傍晚 nextAt；end 不决定下次开始
