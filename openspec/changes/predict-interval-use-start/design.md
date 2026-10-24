## Context

`occurrenceInstant` 对已结束计时（`eventNumber==0` 且有 end）返回 `endTime`，对进行中与 one/number 返回 `startTime`。间隔预测、lastAt 缓存、预测卡「上一次」都走该函数。duration expect 已按 `startTime` 分桶并用 `end−start` 算时长；进行中 ETA 为 `start + duration`。夜间长睡因此在间隔链上变成清晨点，晚上开睡进不了同桶投票。

## Goals / Non-Goals

**Goals:**

- 间隔与 `lastAt` / `nextAt` 的发生时刻统一为开始：已结束 time 也用 `startTime`。
- 保留同桶优先、相邻回退、全桶等权与种子旁路。
- duration / 进行中结束 ETA 继续只用 end 算时长，不拿 end 推下次开始。

**Non-Goals:**

- 不改桶边界、权重数值、半衰期分段。
- 不改 Go；不做独立「预计醒来」预测行。
- 不强制迁移磁盘里旧 tip（新写入自然覆盖）。

## Decisions

1. **单点改 `occurrenceInstant`。** 删除「`eventNumber==0` → endTime」分支；已结束与进行中均：`startTime ?? createdAt`（进行中仍受 `includeActive` 门闸）。所有经该函数的间隔、缓存、UI lastAt 一并对齐，避免双轨。
2. **不拆第二套「结束预测」进 interval。** 结束仍只走 duration expect / active ETA。
3. **缓存语义改为「上次开始」。** 旧 tip 若曾是 end，窗口有记录时以窗口 start 为准；仅缓存旁路时可能短暂偏旧，接受至下次真发生刷新。
4. **规格改写 time 场景。** 「已结束 time 取 endTime」改为取 startTime；补睡眠 start 链场景（上午 lastAt → 傍晚 nextAt）。

## Risks / Trade-offs

- [「上一次」从结束改成开始] → 与「下次何时开始」一致；文案不强制改字，语义跟 lastAt。
- [旧 tip 为 end] → 窗口优先；旁路路径短期偏差可接受。
- [两次开始间隔 &lt;15 分钟被滤] → 保持既有最短间隔，避免噪声。

## Migration Plan

发版客户端即可。回滚恢复 `occurrenceInstant` 的 end 分支并还原规格句。

## Open Questions

无。
