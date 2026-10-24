## Why

间隔预测对已结束的计时记录用 `endTime` 当「发生时刻」，夜间长睡被记成清晨醒来，晚上的开睡点进不了间隔链。白天短睡次数多时，同桶/相邻回退又容易把下次推到上午小睡，丢掉「今晚再睡」这类开始时刻。`endTime` 本就该只服务时长与结束 ETA，不该决定下次何时开始。

## What Changes

- **BREAKING（预测语义）**：间隔推演与 `lastAt` / `nextAt` 对已结束 `time`（`eventNumber==0`）改为使用 **`startTime`**（缺失时 `createdAt`），MUST NOT 再用 `endTime` 作为间隔发生锚点。
- 进行中计时、`one` / `number` 仍用 `startTime`（或既有等价），与本次对齐。
- **不改** duration / amount expect：时长仍为 `end−start`，桶与半衰期仍锚 `startTime`；进行中 `expectEndAt = start + duration` 保持。
- 同桶优先投票、15 分钟最短间隔、种子旁路等间隔门闸保持；仅更换发生时刻来源。
- 经 `occurrenceInstant` 写入的事件最近发生缓存与预测卡「上一次」随之表示「上次开始」。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-interval-prediction`：已结束 time 的发生时刻从 `endTime` 改为 `startTime`；傍晚/清晨同桶场景按 start 链验收。

## Impact

- `app/lib/data/event_next_predictor.dart` 的 `occurrenceInstant`（及依赖它的 `predictNextForEventKey` / `predictAllUpcoming` / lastAt 缓存写入）。
- 预测页「上一次」、小组件、care-alert 等凡读同一发生时刻的表面。
- OpenSpec 基线 `event-interval-prediction` 中「time 取 endTime」条款。
- 不改 Go API；不改 duration expect / active-ETA 规格意图。
