## Why

开事前预测卡/pending 的「预计用时」用 `lastAt`（上次开始）做时段加权锚点，而进行中 ETA 用本次 `startAt`。睡眠等昼夜双峰事件上，常出现「下次开始 19:00 正确、开事前用时贴近日间短睡约 1 小时、开睡后结束却约 10 小时」的自相矛盾。需要把开事前 expect 的查询锚点对齐为「即将发生的那场」——即 `nextAt`。

## What Changes

- 非预约根在已有 `nextAt` 预测上挂载胜出 expect（duration / amount）时，时段桶与半衰期的**查询锚点**改为 `prediction.nextAt`，不再用 `prediction.lastAt`。
- 样本自身的加权时刻规则不变：duration 样本仍按该次 `startTime` 分桶；amount 样本仍按其发生时刻；进行中 ETA 仍按本次 `startAt` 查询。
- 规格补明确：开事前 expect 的「等价锚点」= 预测的下次开始 `nextAt`；与晚间开睡后的 active ETA 语义一致。
- 不改间隔推演（`nextAt = lastAt + interval`）、不改桶边界/权重数值、不改 Go 契约字段名。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-expect-prediction`：明确开事前挂载 expect 时，duration/amount 加权查询锚点 MUST 为该根预测的 `nextAt`（不得再用 `lastAt` 作为查询锚）；补昼夜双峰场景验收。

## Impact

- 代码：`app/lib/data/event_next_predictor.dart` 中 `attachWinningExpect`（及任何直接以 `lastAt` 调用 `resolveWinningExpect` / `confidentDurationExpectSec` 的开事前路径）。
- 下游：`expectDurationSec` / amount 字段写入 imminent pending、卡片次级文案、照护提醒拼接语义会随锚点变化；进行中 ETA（`active_timing_eta.dart`）与间隔预测逻辑保持不变。
- 无 Android/iOS 原生、无后端 API 路径变更；无 **BREAKING** 字段更名。
