## 1. ContentState 解码（对齐已完成 Go twin）

- [x] 1.1 Timing `ContentState` 增加可选 `expectEndAt`（Int64，缺省 0）；旧推送 decodeIfPresent
- [x] 1.2 Imminent `ContentState` 增加可选 `expectKind` / `expectDurationSec` / `expectAmount` / `expectUnit`；缺省空/0；amount 按 Double 解码

## 2. 锁屏 UI

- [x] 2.1 `LockScreenTwoTier` 支持标题列主标题 + 可选副行；无副行不占位；trailing 字号可按调用方覆盖
- [x] 2.2 Timing 锁屏：有正 `expectEndAt` 时副行「预计 HH:mm 结束」；右侧已计时仍用既有 `.title`；Island 不改
- [x] 2.3 Imminent 锁屏：短版 duration/amount 到右侧；右槽字号 = trailing `.title` 基准 − 5pt；无 expect / sec&lt;60 / amount≤0 空右槽；Island trailing 仍空

## 3. 文档与联调

- [x] 3.1 更新 `LIVE_ACTIVITY.md`：ContentState 字段表、短版文案、Imminent 右槽 −5pt；注明 Go twin `live-activity-expect-lock-go` 已完成（title 基句、无预计后缀）
- [ ] 3.2 手工：有/无字段推送；Imminent 右槽明显小于 Timing 已计时；Island Imminent 无 expect、无 nextAt 倒计时回归
