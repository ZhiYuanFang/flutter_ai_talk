## Context

`dailyPointsNearAnchorTod` 在 `[now-6d, now]` 内按天收集 `occurrenceInstant ≤ now`，再选 TOD 距 `nextAt` 最近者。今日因此常落在「已发生」而非预测点。产品冻结：**仅当 nextAt 在今天才画今日点**，且该点为 `nextAt`。

## Goals / Non-Goals

**Goals:**

- 今天：`nextAt` 与本地今天同日 → 点 = `nextAt`；否则今日无点。
- D-6…昨天：保持「每日至多一历史点、贴近 nextAt TOD」。
- 图表尺度包含今日 `nextAt`（即使 `nextAt > now`）。

**Non-Goals:**

- 不改 `event_next_predictor` / `nextAt` 算法。
- 不改推演开关、range 历史拉取、虚线样式本身。
- 不新建测试文件。

## Decisions

1. **今日点来源**  
   `DateTime(nextAt.y,m,d) == DateTime(now.y,m,d)` 时，`chartPoints` 含 `nextAt`；**禁止**再用今日已发生 occurrence 参与「今日代表点」竞选。

2. **nextAt 不在今天**  
   今日列省略；不把「明日 nextAt」投影到今日列。

3. **逾期同日**  
   `nextAt < now` 但仍是今天 → 仍画 `nextAt`（表达预测锚点，非「严格未来」过滤）。

4. **实现落点**  
   在 `dailyPointsNearAnchorTod`（或薄包装）中：先算历史天 `0..5`（或等价「非 today」），再按需追加今日 `nextAt`；调用方继续传 `anchorTod: pred.nextAt`。

5. **Y 轴**  
   `_LookbackChart`（或等价）在计算 min/max 时纳入 `anchorTod` / 今日点，避免未来时刻被裁切。

## Risks / Trade-offs

- **[Risk] 今日已发生多次、nextAt 在明天 → 今日无点** → 产品接受（「仅 nextAt 在今天才画」）。  
- **[Trade-off] 逾期 nextAt 仍画在过去 TOD** → 与倒计时「已超时」文案一致，仍作锚点。

## Migration Plan

1. 改取点 + 图表尺度。  
2. 手工：nextAt 今天 → 今日点在预测时刻；nextAt 明天 → 今日无点。  

回滚：恢复「今日也从 ≤now occurrence 选最近点」。

## Open Questions

- 无。
