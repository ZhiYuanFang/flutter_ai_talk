## 1. 喂养页 C 态初值

- [x] 1.1 修改 `_onNextPredictGlassCta`：C 态保留 `forceRecordSheet: true`，`initialStartTime` 改为不传 / `null`（不再传 `prediction.nextAt`）
- [x] 1.2 同步更新该处注释（去掉「开始=预测时刻」表述）

## 2. 回归核对

- [x] 2.1 全仓确认无其它 C/补记入口仍向 create sheet 预填 `nextAt` 作为开始时间
- [x] 2.2 手工：C 态点「补记」→ sheet 开始时间 ≈ 当下，且 `time` 事件仍开 sheet 不直开计时；A/B 行为未变
