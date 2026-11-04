## 1. 开事前 expect 查询锚

- [x] 1.1 在 `app/lib/data/event_next_predictor.dart` 的 `attachWinningExpect` 中，将 `resolveWinningExpect` 的 `anchorAt` 从 `prediction.lastAt` 改为 `prediction.nextAt`
- [x] 1.2 全文检索确认无其它开事前路径仍以 `lastAt` 调用 `resolveWinningExpect` / 为挂 expect 而调用 `confidentDurationExpectSec`（进行中 ETA 的 `startAt` 调用保持不动）

## 2. 验收

- [x] 2.1 对照 `event-expect-prediction` 新增场景：昼夜双峰 + 上午 `lastAt` + 傍晚 `nextAt` 时，开事前胜出 duration 贴夜间长睡量级；开睡后 ETA 仍以本次 `startAt` 为锚
- [x] 2.2 确认 imminent pending 指纹含 expect 时会随新 `expectDurationSec` 触发一次同步（无需改仓库协议）
