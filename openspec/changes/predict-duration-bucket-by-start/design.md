## Context

`_durationSamplePoints` 现将样本 `at` 设为计时 **endTime**，再交给与间隔预测相同的时段桶 + 半衰期加权中位。进行中 ETA 的 `anchorAt` 为本次 **startAt**。跨午夜长睡（晚开始、早结束）按 end 落入清晨桶，晚上开睡时权重偏低，日间/傍晚短睡更容易主导中位。

## Goals / Non-Goals

**Goals:**

- duration 样本的桶权与半衰期锚点改为该次计时的 **startTime**（方案 A）。
- 进行中 ETA 与卡上 duration expect 共用修正后的量线。

**Non-Goals:**

- 不改 amount 样本时间语义、间隔 `nextAt`、桶边界/半衰期常数、门闸与放宽桶策略。
- 不做「分桶用 start、新旧用 end」的拆分（方案 B）；不做仅 ETA 专用采样（方案 C）。

## Decisions

### D1：样本 `at = start`

- **选择**：`durationPoints.add((at: start, value: sec))`；value 仍为 `end.difference(start).inSeconds`。
- **理由**：与「还要睡多久 ≈ 以往同时间段**开睡**多久」一致；一行改动，卡与 ETA 同受益。
- **备选 B**（桶 start / 新旧 end）收益有限、接口更绕；**备选 C** 双路径易漂移。

### D2：与 one 排除等并行 change

- 假定工作树已含 `predict-expect-one-exclude-layout` 对 duration 采点的 catalog 过滤；本变更只改 `at` 字段语义，不回退 one 规则。
- 规格 MODIFIED 以「含 one 排除 + start 锚点」的完整 dual-modal 需求为准，便于归档叠合。

### D3：同步副作用

- durationSec / expectEndAt 变化后，既有 imminent expect 指纹与 active-eta 指纹会自然重 PUT；无需新触发器。

## Risks / Trade-offs

- [极短误触计时] → start 靠近真实意图时段仍合理；不另做过滤。
- [跨时区旅行] → 与现网其它本地桶一致，不在本变更处理。
- [放宽桶仍混长短睡] → 同桶夜间样本充足时优先严格桶；放宽仍是全局兜底，无法消灭但夜间不再被系统性降权。

## Migration Plan

- 纯客户端：热更后重算即可。
- 回滚：`at` 改回 `end`。

## Open Questions

（无。）
