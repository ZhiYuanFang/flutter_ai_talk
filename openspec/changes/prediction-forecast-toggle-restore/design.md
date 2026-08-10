## Context

推演关闭集合与 store 仍在，但预测页 UI 与 provider 已写死空集；小组件 sync 从未过滤 disabled。产品要求恢复小开关（含网格）、关推演不进留意跑马灯，且小组件同步排除。

## Goals / Non-Goals

**Goals:**

- list/grid 均有紧凑推演开关；默认 ON；本地持久化。
- OFF：无图、无相对时间、置灰；tip 排除；留意跑马灯排除。
- 小组件预测行排除 OFF 事件；toggle 后触发 `scheduleHomeWidgetSync`（既有 single-flight）。

**Non-Goals:**

- 不改推演公式/阈值；不改 tip 底栏形态；不新开 HTTP 通道。

## Decisions

### D1：控件

- 迷你 `Switch.adaptive`（`Transform.scale` ≈ 0.75–0.85）或同占位小图标切换；行尾对齐事件名。
- 网格与纵向同一交互；tooltip/语义「推演」。

### D2：预测页数据

- `smartPredictionRowsProvider` 再次传入 `forecastDisabledIdsProvider`。
- OFF 行：`forecastEnabled=false`，无 prediction/chartPoints（既有 `buildSmartPredictionRows` 行为）。
- `homePredictionTipProvider` 再次传入 disabled 集合。

### D3：值得留意

- `predictionCareAlertProvider`：在 `evaluateCareAlertEventItems` 之后（或之前）**过滤** `eventId ∈ disabled`。
- 不要求改规则阈值本身。

### D4：小组件

- `buildHomeWidgetPayload`：`predictAllUpcoming` 前过滤 disabled 事件的 history/activeKeys，或对 predictions 结果按 disabled 剔除（与页内一致优先）。
- 读取：`ForecastToggleStore.loadDisabledIds()`（sync 路径无 Riverpod 时直读 store）。
- `ForecastDisabledIdsNotifier.setEnabled` 成功后 `unawaited(scheduleHomeWidgetSync(ref))`（或等价入口）；遵守副作用 HTTP 治理。

### D5：与 layout change 关系

- `prediction-layout-list-grid` REMOVED「Per-event forecast toggle」；本 change **ADDED** 恢复版 Requirement（含网格 + 小组件 + 留意）。

## Risks / Trade-offs

- [网格拥挤] → 迷你 scale，去掉「推演」长标签。
- [sync 风暴] → 复用 `scheduleHomeWidgetSync` debounce/single-flight。
- [留意与推演语义] → 产品已定：关则不进跑马灯。

## Migration Plan

- 旧 disabled 键继续有效；无迁移。

## Open Questions

- （无）迷你 Switch 为默认形态。
