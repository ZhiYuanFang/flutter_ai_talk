## Context

热态卡用 `showLastOccurrence = !计时中 && onToggle!=null`，再无条件调用 `formatPredictionLastOccurrenceLabel`；`lastAt==null` 时 `formatWidgetLastAt` 返回「暂无」，整行变成「上一次{名}：暂无」。同卡另有 `showAddLastOccurrence`（`lastAt==null` 等）渲染「补充上一次」。切号 wipe tip 后短暂无 lastAt 会误显「暂无」。

## Goals / Non-Goals

**Goals:**

- 无 `lastAt` → 不渲染「上一次」行（无「暂无」）。
- 有 `lastAt` → 仍展示可读时刻行（可点编辑规则不变）。
- 无 `lastAt` → 仍可出「补充上一次」，服务冷启动与空态补记。

**Non-Goals:**

- 不改 `buildSmartPredictionRows` 的 lastAt 合并（历史 ?? tip）。
- 不改 tip wipe / 切号策略。
- 不强改桌面小组件文案（除非共用函数被迫调整且易测）。

## Decisions

### 1. 门闩在卡侧

```
showLastOccurrenceRow = 热态 && !计时中 && row.lastAt != null
```

有值才 `formatPredictionLastOccurrenceLabel`；否则 `lastOccurrenceLabel = null`（现有 `if (label != null)` 即不占位）。

### 2. CTA 独立

`showAddLastOccurrence` 条件保持（含 `lastAt == null`）；与藏行正交，保证新用户仍见补记入口。

### 3. 规格改写「暂无」义务

`event-last-at-cache` 要求皆无显示「暂无」→ 改为皆无 **MUST NOT** 渲染上一次行。

## Risks / Trade-offs

- **[Risk] 新用户少一行提示** → **Mitigation**：保留心跳「补充上一次」。
- **[Risk] 切号后短时空窗** → 无行优于假「暂无」；历史到达后自然出现行。

## Migration Plan

- 纯 UI；热重载可验。
- 回滚：恢复无条件展示 label 即可。

## Open Questions

- （无）
