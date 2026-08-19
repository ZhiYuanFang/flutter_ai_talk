## Context

- 智能预测页经 `smartPredictionRowsProvider` 消费 `predictionHistoryWithRecallSeedsProvider`（7 日 range + 种子）与 `eventCatalogProvider`，并滤 `forecastDisabledIdsProvider`。
- 小组件经 `syncHomeWidgetFromRef` → `buildHomeWidgetPayload` → `predictAllUpcoming`，当前默认 `historyOverride ?? ref.read(homeHistoryProvider).items`，catalog 走磁盘 `EventCatalogStore.loadFromDisk()`，未滤推演关闭。
- `ensureWidgetHistoryDepth` 已委托 `predictionRangeHistoryProvider.ensureLoaded()`，但 range 成功写 state 后 **未** 回调 widget sync。
- 历史 WS/本地变更：`homeHistoryNotifier._applyState` 会 `scheduleInvalidation()` + `scheduleHomeWidgetSync(history: items)`——后者仍推 home 分页快照给 widget，而非 range 结果。
- 副作用 HTTP 治理：widget sync 须 single-flight（已有 `_widgetSyncInFlight`）；range ensure 须 single-flight（已有 `_inFlight`）；**禁止**在 provider `build()` 内无门控自动 HTTP/sync。

## Goals / Non-Goals

**Goals:**

- 小组件 hero / recentLast 与预测页在相同 login、相同 range ready、相同 catalog/推演开关下，对同一 `eventId` 给出一致 `nextAt`（skip 过滤仍仅作用于 hero，保持现有 S1 语义）。
- range 从 loading→ready 或 items 变化后，桌面 payload 在合理延迟内更新。
- 消除 `firstPageOnlyCached` 导致 range/widget 不同步的早退漏洞。

**Non-Goals:**

- 不改变 native 小组件布局、tip chat HTTP、hero skip 交互。
- 不合并 `homeHistoryProvider` 与 range store。
- 不新增后端接口；不调整 7 日窗算法或 `predictAllUpcoming` 数学模型。
- 回忆种子 onboarding UI 不变；仅 widget 读取侧与预测页对齐。

## Decisions

### 1. 抽取共享「widget 预测输入」Provider

新增轻量 `Provider`（如 `widgetPredictionHistoryProvider`）复用 `predictionHistoryWithRecallSeedsProvider` 同一 merge 逻辑，或直接 `ref.read(predictionHistoryWithRecallSeedsProvider)`。`syncHomeWidgetFromRef` 在 logged-in + ready 态读取该列表，**不再** read `homeHistoryProvider.items`。

**理由**：单一真相源，避免 sync 路径与 UI 分叉。  
**备选**：在 sync 内手写 merge——拒，易再次漂移。

### 2. Catalog 与推演过滤

- catalog：`ref.read(eventCatalogProvider).items`（必要时 await catalog ensure，若 store 未 hydrate 则沿用 notifier 已有路径）。
- 推演关：`predictAllUpcoming` 前滤 `forecastDisabledIdsProvider`，与 `buildSmartPredictionRows` / `pickNearestPrediction` 一致。

### 3. Widget sync 触发点

| 事件 | 动作 |
|------|------|
| range `_loadImpl` 成功（ready=true） | `unawaited(scheduleHomeWidgetSync(ref))` |
| range debounce 重拉成功 | 同上 |
| `homeHistoryNotifier` 变更 | 保留 `scheduleInvalidation()`；**移除**向 sync 传 home-only `historyOverride`（或 override 改传 range items 快照——优先不传，让 sync 自读 provider） |
| `firstPageOnlyCached` 早退 | 仍 `scheduleInvalidation()` + `scheduleHomeWidgetSync` |
| 推演开关变更 | 已有 `forecast_toggle_provider` → 保持 |

在 `app.dart` 或 `UcgHomeShell` 增加 `ref.listen(predictionRangeHistoryProvider, …)`：**仅**当 `ready` 且 items/loading 边沿变化时 schedule sync；**不得**在首帧构造时重复 ensure。

**理由**：listen 边沿触发符合「非 provider 构造自动 push」；与 care-alert listen 模式一致。

### 4. `historyOverride` 参数

 deprecate 热路径 home 快照：WS/setItems 仍可调 `scheduleHomeWidgetSync(ref)` 无 override。若保留参数，文档注明仅测试/过渡；实现忽略 override，统一读 range provider。

**理由**：override 是 homeHistory 自依赖 workaround，range 时代不再需要。

### 5. Loading / empty 态

- range 未 ready 且 widget 冷启：`ensureWidgetReadyFromRef` 已有 loading payload → 保持。
- range ready 但预测为空：沿用现有 empty / noPrediction 文案逻辑。

## Risks / Trade-offs

- **[Risk] sync 频率上升（range 重拉 + home 变更双触发）** → 已有 single-flight 合并；range debounce 280ms 与 widget sync loop 叠加可接受。
- **[Risk] catalog 内存未 hydrate 时 widget 无事件名** → read `eventCatalogProvider` 前确保 notifier 已 load（与预测页相同 cold path）；磁盘 fallback 仅作 catalog async loading 中间态 optional。
- **[Risk] 回忆种子使 widget 在空库时展示预测** → 与预测页一致，产品预期；空库无种子仍 empty。
- **[Trade-off] widget 不再反映「仅首页有、7 日窗外」的旧记录** → 符合 7 日窗产品范围。

## Migration Plan

1. 改 `syncHomeWidgetFromRef` / `buildHomeWidgetPayload` 输入源与过滤。
2. range 成功回调 + listen 补 sync；修 `firstPageOnlyCached`。
3. 移除或忽略 home `historyOverride` 调用方传参。
4. 手工：改一条记录 → 预测页与小组件 hero 一致；杀进程冷启 → loading→ready 后一致；关推演 → 小组件隐藏该事件。

## Open Questions

- 无。catalog 若 cold 未就绪，与预测页同样依赖 `eventCatalogProvider` 首次 hydrate（现有行为）。
