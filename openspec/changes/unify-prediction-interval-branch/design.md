## Context

当前稀疏路径通过 `mergeHistoryWithRecallSeeds` 注入 3 条伪记录，让 `predictNextForEventKey` 的加权中位「碰巧」≈ `seed.interval`，同时 `row.lastAt` 也吃合并历史。编辑路径却用真历史 → 套娃；删光后 sample gate 永不达标 → 种子永留 → countdown 幽灵。

约束：不新建测试；不恢复 Dialog；主题色/WS/副作用 HTTP 惯例不变；基线 `event-interval-prediction` 的加权中位与 15 分钟门槛保留。

## Goals / Non-Goals

**Goals:**

- 单一推演：`nextAt = lastAt + interval`；仅间隔来源分岔。
- `lastAt`（行展示、预测、间隔 CTA 锚）= 真喂养最新；无真则无预测。
- 退役预测路径上的伪 `HistoryRecord` merge。
- 该 root 真记录清空 → 清种子 + 无预测 UI。
- 删除乐观同步 range，避免并集滞后。

**Non-Goals:**

- 改时间后自动重锚 `seed.lastAt` / `occurrenceAts`（可后续）。
- 重写 TOD 桶 / 半衰期公式。
- 删除 OnboardingPanel 死代码、量身定做 Dialog 源码清理。
- 服务端 / care-alert / Android 原生。
- 新建 `**/test/**`。

## Decisions

### D1：间隔分岔，公式唯一

**选择**：抽取/扩展 per-root 预测入口：

```
lastAt = latestRealOccurrence(home∪range)   // 无 → null → 无预测
if sampleGate(real): interval = weightedMedian(real)
else if seed?.interval ok: interval = seed.interval
else: 无预测
nextAt = lastAt + interval
```

**替代**：继续伪记录伪装 — 拒绝（双兼容税）。  
**理由**：与产品「两套合一套」一致；种子只是 interval 配置。

### D2：冷启动严格无真不预测

**选择**：零真记录时即使用户曾写种子，也 **不得**用 `seed.lastAt` 产出预测；卡上「暂无」+「补充上一次」。

**替代**：允许 seed.lastAt 作临时锚 — 拒绝（与「清空=无记录」冲突，且 Dialog 已退）。  
**理由**：explore 已拍板方案 A。

### D3：`row.lastAt` 与编辑同源

**选择**：`buildSmartPredictionRows` 的 `lastAt` 用 `latestRealHistoryRecordForRootFromSources`（或等价）的 occurrenceInstant；预测 `EventNextPrediction.lastAt` 同值。

**理由**：消灭展示/编辑分叉。

### D4：退役 merge 进预测

**选择**：`predictionHistoryWithRecallSeedsProvider` 改为真历史直通（或改名）；`syntheticHistoryRecordsFromSeed` / `mergeHistoryWithRecallSeeds` 不再被预测调用（可删或标废弃）。种子 map 单独传入行构建/预测。

**注意**：种子 JSON 仍可含 `occurrenceAts` 以兼容旧存储；推演 **忽略**合成点。

### D5：空库弃种子

**选择**：某 root 在真历史并集中条数为 0（或无任何 occurrenceInstant）时，`clearSeeds([rootId])`；merge/预测均不得再读该种子。

**替代**：仅软忽略不删持久化 — 较弱，重装/重算仍易幽灵。  
**理由**：产品要求清空后不得「另一套以为还有」。

### D6：删除乐观同步 range

**选择**：`homeHistory.removeRecord`（及等价 replace 若需）同步从 `predictionRangeHistoryProvider` items 去掉同 id，再保留既有 debounce refetch。

**理由**：并集「home 覆盖同 id」无法表达删除；否则删后 lastAt 仍短暂/长期旧。

### D7：图表过去点仅真记录

**选择**：`dailyPointsNearAnchorTod` 只喂真记录；种子路径可能仅有今日 nextAt 点。

**理由**：不再画假历史点。

### D8：per-card 确认仍 upsert 种子

**选择**：间隔 Sheet 确认仍写 `PredictionRecallSeed`（含 interval、可选 lastAt 快照字段）；生效改为「下一帧 interval 分岔读 seed.interval」，不依赖合成点数量。

**理由**：最小改动 UX；契约从「伪历史」变为「间隔旁路」。

## Risks / Trade-offs

- **[Risk] 旧客户端已写入的仅种子、零真记录用户失去 countdown** → 接受；引导「补充上一次」写真喂养。  
- **[Risk] 删光后若漏清种子** → 规格强制 clearSeeds；provider 行构建侧双检。  
- **[Risk] home 分页不含旧记录、range 有** → 并集仍以 range 补齐最新；删除 tombstone 仍必要。  
- **[Trade-off] 种子 confidence** → 可用固定偏低；UI 若不展示 confidence 可忽略。  
- **[Trade-off] occurrenceAts 字段冗余** → 暂保留反序列化兼容，推演不用。

## Migration Plan

1. 发版后预测不再 merge；已有种子在「有真 lastAt + 未达标」时仍提供 interval。  
2. 零真 + 仅种子 → 预测消失（预期）。  
3. 回滚：恢复 merge provider（不推荐）；无服务端迁移。

## Open Questions

（无阻塞；改时间重锚种子留后续。）
