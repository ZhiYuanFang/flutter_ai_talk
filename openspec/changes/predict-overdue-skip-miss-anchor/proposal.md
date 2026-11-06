## Why

亲和间隔算法本身可用，但逾期后卡在错误/未发生的 `nextAt` 时用户无法干预。需要在**仅逾期**时提供「跳过本次」：不改真历史，以被跳过的错过点为亲和锚与加法起点重算下一档预测。

## What Changes

- 热态非预约预测卡在 `nextAt` 已逾期时 MUST 展示「跳过本次」（或等价文案）控件；未逾期 / 预约 / 无 pred MUST NOT 展示。
- 用户确认跳过时：将该根当前 `nextAt` 持久化为 `missAnchor`；MUST NOT 写入喂养历史、MUST NOT 把错过点计入直方图发生样本。
- 重算：亲和钟点锚与 `nextAt = missAnchor + interval` 的加法起点均为 `missAnchor`；卡上展示用的真 `lastAt` 仍为真发生 tip。护栏 / 先热后软语义保持。
- 一次点击只推进一档（`missAnchor ← 当前 nextAt` 后重算一次）；若结果仍逾期，控件仍在，可再点。
- 该根出现新的真发生且 tip ≥ `missAnchor`（或明确更新于错过点之后）时 MUST 清除 `missAnchor`。
- 智能预测卡、小组件、pending 等消费同一预测结果的路径 MUST 使用跳过后的 `nextAt`（不得与 App 卡分叉）。
- MUST NOT 复用 `WidgetHeroSkipStore`（那是换事件，不是同事件推档）。
- **不做**：改亲和带宽/直方图阈值；预约跳过；自动连跳到未来（仅手动逐次）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-interval-prediction`：支持按根 `missAnchor` 的亲和锚与加法起点旁路。
- `smart-prediction-page`：逾期卡「跳过本次」UI 与清除时机。

## Impact

- 代码：`event_next_predictor`（可选锚）、missAnchor 本机存储、预测行组装、`smart_prediction_screen` 按钮；小组件/pending 随统一预测输出。
- 规格：对照 `openspec/specs/v2.1.4.md`；与 `predict-tod-cold-soft-label` 软标正交。
- 无 Go API / 无原生 SDK 契约变更（若小组件仅吃 Flutter 算好的 nextAt 则无需改 native 协议）。
