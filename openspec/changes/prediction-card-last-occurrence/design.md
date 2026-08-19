## Context

- 预测行由 `buildSmartPredictionRows` 构建；`prediction` 仅在样本 ≥2 且推演开启时存在，但卡片仍可为该 root 渲染（`forecastEnabled: false` 或 `prediction: null`）。
- `_PredictionEventCard` 第二行现用 `Align(centerRight)` 将 `relativeText`（网格 overdue 为「超时 X 分钟」）与 `toggleCaption` 挤在右侧。
- 小组件已用 `formatWidgetLastAt` 格式化上次时刻；`EventNextPrediction.lastAt` 与展示用 last 在可预测场景应一致。

## Goals / Non-Goals

**Goals:**

- 热态卡片（非计时中、非骨架）均靠左展示「上一次{titleName}：{time}」。
- caption 第二行：左 relativeText、右 toggleCaption。
- `SmartPredictionRow.lastAt` 在构建时一次算好，卡片不读 history 列表。

**Non-Goals:**

- 不改第 445 行缺省页逻辑、不改 `predictAllUpcoming` 算法。
- 不改小组件 native payload（除非后续单独对齐）。
- 冷态骨架/demo 不展示「上一次」。

## Decisions

### 1. `lastAt` 计算

在 `buildSmartPredictionRows` 对每个 `entry.value`：

```dart
lastAt = max(occurrenceInstant(r, includeActive: true) for r in records)
```

与 `event_next_predictor.occurrenceInstant` 同源；`includeActive: true` 以便仅一条进行中记录时仍有展示值（计时中卡片 UI 层豁免，不渲染该行）。

### 2. 展示豁免（UI）

| 条件 | 展示「上一次」 |
|------|----------------|
| `showActiveTiming` | 否 |
| `onToggle == null`（骨架） | 否 |
| 其余热态 | 是（含推演关、无 pred） |

### 3. 布局

- **第二行**：`Row` + `MainAxisAlignment.spaceBetween`；左 `Flexible` relativeText，右 `Flexible` toggleCaption；去掉 `Align(centerRight)`。
- **第三行**：全宽左对齐 `Text`；`captionFontSize` + muted 色；与 relative 行间距 `sectionGapSm`。
- 列表/网格共用 `_PredictionEventCard`，改一处即可。

### 4. 文案

`formatPredictionLastOccurrenceLabel(titleName, lastAt, now)` → `上一次$titleName：${formatWidgetLastAt(lastAt, now)}`；`lastAt == null` 时用「暂无」。

## Risks / Trade-offs

- **[Risk] 长事件名 + 长 caption 挤占]** → 左右 `Flexible` + `ellipsis`。
- **[Risk] 推演关 lastAt 与 pred.lastAt 不一致]** → 可预测时 assert/注释两者应对齐；展示只用 `row.lastAt`。
- **[Trade-off] 网格未 overdue 无 relativeText]** → 仅「上一次」一行靠左，符合产品「都要有」。

## Migration Plan

1. 扩展 `SmartPredictionRow` + 构建逻辑。
2. 调整 `_PredictionEventCard` caption 与第三行。
3. `flutter analyze`；真机扫列表/网格/计时/骨架/推演关。

## Open Questions

- 无。
