## Context

卡上次级文案现由 `formatPredictionExpectCardLabel` 生成，在 `_PredictionEventCardState`（`smart_prediction_screen.dart`）中当 `pred.hasExpect && !showActiveTiming` 即赋给 `expectLabel`，再经 `_buildExpectAboveCountdownLine` 贴在倒计时上方。`overdue` 已由 `pred.isOverdue(now)` 算出并用于倒计时 HMS，但未参与 expect 门闩。计时中 ETA 走独立的 `activeEtaLabel`，与 expect 无关。

## Goals / Non-Goals

**Goals:**

- 卡上永不展示 duration expect 文案。
- amount expect 仅在 `overdue == true` 时展示。
- 无文案时不占位（沿用现有 null → 不渲染）。

**Non-Goals:**

- 不改 `event_next_predictor` 胜出逻辑、不改 pending `expectAmount` / `expectDurationSec` 上报。
- 不改计时中 `activeEtaLabel` / 停止按钮区。
- 不改倒计时 HMS、「已超时」倒计时样式本身（仅 expect 行可见性）。

## Decisions

### 1. 展示门闩放在卡侧，不删引擎字段

- **决策**：在计算 `expectLabel` 时按 kind + overdue 过滤；`formatPredictionExpectCardLabel` 可保持纯格式化，或加可选参数——优先在卡侧 if，改动面最小。
- **理由**：pending / 指纹仍需要 expect；产品只调 UI。

### 2. duration 一律不展示

```
hasExpect && kind==duration → expectLabel = null（卡上）
```

### 3. amount 仅 overdue

```
hasExpect && kind==amount && overdue → format… 
否则 → null
```

`overdue` 与倒计时共用 `pred.isOverdue(now)`。

### 4. 计时中路径不动

- `showActiveTiming` 分支不读 `expectLabel` 展示 expect；本变更不得改 `activeEtaLabel` 条件。

## Risks / Trade-offs

- **[Risk] 用户超时时才看到用量，未到期无提示** → 产品有意降噪；**Mitigation**：规格写明。
- **[Risk] 引擎仍算 duration expect 但永不展示** → 可接受；日后若要停算再开 change。
- **Trade-off**：UI 与「有胜出即展示」旧规格不一致，以本 delta 为准。

## Migration Plan

- 纯客户端；热重载即可验收。
- 回滚：恢复 `hasExpect` 即展示即可。

## Open Questions

- （无）计时中 ETA 已确认不动。
