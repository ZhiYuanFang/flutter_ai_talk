## Why

duration 量线目前用历史计时的 **结束时刻** 做时段桶与半衰期锚点，而进行中 ETA 以 **本次开始时刻** 为锚。夜间长睡常在清晨结束，分桶落到白天，晚上开睡时权重被压低，中位被傍晚/日间短睡拉短——体感「晚上开睡却像按白天小睡估」。

## What Changes

- duration 样本用于时段桶与半衰期的时间戳 MUST 改为该次计时的 **`startTime`**（方案 A）；样本值仍为 `end-start` 秒。
- 共用 `_durationSamplePoints` 的路径一并受益：热态卡胜出 duration 的「预计约…」、进行中 `expectEndAt = start + durationSec`。
- **不改**：桶边界定义、半衰期分段、≥2 门闸、放宽桶回退、amount 线、`nextAt` 间隔（间隔侧仍用发生时刻，本变更不碰）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-expect-prediction`：明确 duration 样本的加权时间锚为计时 **开始** 时刻（修正 `predict-expect-amount-duration` 引入、且可能已被 `predict-expect-one-exclude-layout` 改写的双线规则）。
- `predict-active-timing-eta`：补充场景——晚上开睡时夜间长睡样本须相对日间短睡获得合理时段权重（公式仍为 start+durationSec，行为随 duration 线修正）。

## Impact

- 代码：`event_next_predictor.dart` 中 `_durationSamplePoints`（`at: start`）；调用方无需改签名。
- 无新 HTTP / Go 契约变更；active-eta / imminent 字段不变，仅数值可能变化并触发既有指纹重同步。
- 无 Android 原生改动。
