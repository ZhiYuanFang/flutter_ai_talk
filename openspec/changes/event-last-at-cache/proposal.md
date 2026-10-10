## Why

智能预测主页事件卡的「上一次」时刻来自 `home∪range` 真历史窗口。某事件真实上次发生若落在预加载分页/range 之外，卡上 `lastAt` 为空，误显示「暂无」并可能误走补充流。需要在**不扩分页、不加新 HTTP** 的前提下，用本机见过的真记录记住每宝宝每事件的最近发生时间并回退展示。

## What Changes

- 新增按 `deviceNo` 隔离的本地缓存：`eventId（目录根）→ 最近一次发生时刻`（仅真喂养，非回忆种子）。
- 历史进内存（home/range 合并、WS/新增/更新）时以 `max` 写入/刷新缓存；删除可能打到「当前最新」时失效或按仍可见记录重算该根。
- 预测卡组行：`lastAt = 窗口内 latestOccurrence ?? 缓存`；用于「上一次」文案与「是否有上次」判断。
- **不得**与 `PredictionRecallSeed` 混存或共用清理逻辑。
- 不新增服务端「每事件最近一次」接口；不强制加长 range。

## Capabilities

### New Capabilities

- `event-last-at-cache`：宝宝维度事件最近发生时间本地缓存的读写与失效约定。

### Modified Capabilities

- `event-interval-prediction`：预测表面展示用 / 行级 `lastAt` 在窗口未命中时 MUST 可回退本地真记录缓存；缓存时刻仍视为真 `lastAt`（非 seed 伪锚点）。
- `smart-prediction-page`：热态卡「上一次」展示与有无 lastAt 分支 MUST 遵循上述回退。

## Impact

- 新建 store（如 `event_last_at_store.dart`）+ provider/观察写入点；`smart_prediction_rows`（或等价）读兜底。
- 历史 notifier / range / 成功入列路径触及写缓存。
- 无 Go API 变更；与回忆种子、桌面小组件 recall map 解耦（小组件若共用行构建可顺带受益）。
