## Why

预测页进行中计时只展示已过时长，家长无法看到「大概何时结束」。意图智能体播报进行中时同样缺少预计结束。客户端已有 duration 量线（`predict-expect-amount-duration`），应用其推算进行中 `expectEndAt`，展示并同步到 Go Redis，供 Python intent 查询。

## What Changes

- 对进行中 `time` 记录：当根 duration 线有把握时，计算 `expectEndAt = startAt + expectDurationSec`。
- 预测页**列表与网格**进行中卡均展示预计结束；超时文案保留原预计点并标注「已超时」。
- 独立于 `predict/imminent/pending`：新增全量同步进行中 ETA 到 Go（空列表清空）；字段含根/叶子 eventId、可选 historyId、startAt、expectEndAt、title。
- **不改**下次发生推送、imminent MQ；无 duration 把握时不展示、不同步该项。
- 兄弟仓：`go_ai_talk` / `python_ai_talk` 同名 change（Redis、internal GET、intent `speak_history` 播报）。

## Capabilities

### New Capabilities

- `predict-active-timing-eta`：进行中预计结束的推算、卡片展示、App→Go 同步契约（客户端侧）。

### Modified Capabilities

- `smart-prediction-page`：列表与网格进行中卡 MUST 在有 ETA 时展示预计结束（含超时 A 文案）。

## Impact

- 代码：预测卡进行中 chrome、duration expect 复用、新 repository/sync provider（副作用 HTTP 治理）。
- 依赖：`predict-expect-amount-duration` 的 duration 门闸与格式化。
- 跨仓字段与路径以本仓 design 与 Go 同名 change 对齐。
