## 1. duration 样本锚点

- [x] 1.1 `_durationSamplePoints`：加权用 `at` 改为计时 `startTime`（value 仍为 end−start 秒）
- [x] 1.2 确认 `confidentDurationExpectSec` / `resolveWinningExpect` 无需改签名，行为随采点更新
- [x] 1.3 注释标明：时段桶与半衰期锚 start，不得用 end

## 2. 手工验收

- [ ] 2.1 睡眠根：有夜间长睡（晚 start）与日间短睡；晚间开睡进行中 →「预计约 HH:mm 结束」贴近夜间时长，而非日间短睡
- [ ] 2.2 同根热态卡若胜出 duration：「预计约…」与进行中 ETA 所用 duration 线一致（均按 start 加权）
