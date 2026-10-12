## Why

热态预测卡在 `lastAt == null` 时仍渲染「上一次{名}：暂无」。切号 wipe 掉 tip、历史尚未灌回时会误显「暂无」；真无记录时也与下方「补充上一次」重复、偏噪。需要：**没有上次发生时刻就不展示该行**，同时 **保留「补充上一次」**，保证冷启动新用户仍能补记。

## What Changes

- 热态卡：仅当 `SmartPredictionRow.lastAt != null` 时展示「上一次…」行；`lastAt == null` 时 **MUST NOT** 渲染该行（含不得展示「暂无」）。
- `lastAt == null` 且开推演等既有条件满足时，**MUST** 继续展示「补充上一次」CTA（冷启动 / 无记录路径）。
- `lastAt` 解析语义（home∪range ?? tip 缓存）不变；不改 tip 落盘 / wipe 策略。
- 计时中、骨架卡等既有不展示「上一次」的路径保持不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：修改「Card lastAt / 上一次」展示——无 lastAt 时隐藏行而非显示「暂无」；明确保留「补充上一次」。

## Impact

- UI：`smart_prediction_screen.dart` 中 `showLastOccurrence` / `lastOccurrenceLabel` 门闩。
- 可选：`formatPredictionLastOccurrenceLabel` / `formatWidgetLastAt` 的「暂无」仅当其它调用方仍需要时保留；卡路径不再依赖。
- 与 `event-last-at-cache` 中「皆无则显示暂无」冲突处，以本 change 为准。
