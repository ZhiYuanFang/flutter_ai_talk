## Context

预测页（`SmartPredictionScreen`）数据来自 `homeHistory` ∪ `predictionRangeHistory` 派生行。进页 `predictionRangeEnsureProvider`、home/WS `scheduleInvalidation`、以及 `UcgHomeShell` resume bundle 会刷新，但卡片区无用户手势入口。空态为不可滚 `Center`，列表为 `ListView`，瀑布为 `_WaterfallCards`（`SingleChildScrollView`）；固定 header/timeline 在卡片区之上。

既有约束：range/home 均有 single-flight；range 连续失败 ≥ 阈值后非 force ensure 会 skip；`ensureLoaded(force: true)` 已绕过熔断检查，但**不**清零 `_consecutiveFailures`；失败路径多吞异常、不抛错，不利于 Toast。

## Goals / Non-Goals

**Goals:**

- 卡片区顶部下拉 → 刷新 home 第 1 页 + 强制重拉 7 日 range。
- 下拉开始重置 range 熔断计数。
- 任一路失败 Toast；空态/短列表可拉。
- 竖屏与横屏同一套卡片区挂点。

**Non-Goals:**

- 底部上拉刷新。
- 整包 resume（care-alert / UCG unread 等）。
- 下拉路径直接打 imminent / active-ETA PUT。
- 改 range API 形状或喂养「触顶加载更多」语义。
- 重构整页为单一 `CustomScrollView`（除非实现时内层包裹不够）。

## Decisions

### 1. 刷新范围 = B（home 第 1 页 + range）

- **选择**：`HomeHistoryNotifier.refreshFromRemote()` + `PredictionRangeHistoryNotifier.ensureLoaded(force: true)`（或薄封装）。
- **理由**：预测行依赖并集；只刷 range 时 home 最新页仍可能旧。
- **备选否决**：仅 range（A）— 用户「刷一下」预期不足；整包 resume（C）— 过重且易与 shell 双拉。

### 2. 熔断：手势路径显式清零

- **选择**：下拉 `onRefresh` 入口先将 `_consecutiveFailures = 0`（公开 `resetCircuitBreaker()` 或 `ensureLoaded(force:, resetCircuit: true)`），再 force 拉取。
- **理由**：产品要求「用户主动再试」；仅靠 force 绕过而不清零时，后续非 force 自动 ensure 仍可能 skip。
- **备选否决**：只依赖现有 `force` 绕过而不清零 — 不满足「重置熔断计数」。

### 3. 失败可观测 + Toast

- **选择**：手势路径聚合两路结果；任一路失败 → `showAppToast(..., tone: AppToastTone.error)`（文案如「刷新失败，请稍后重试」）。必要时让 ensure / refresh 返回 `bool` 或抛出/包装失败，避免静默 `return`。
- **理由**：resume 可静默；用户手势需要反馈。
- **备选否决**：完全静默 — 与产品选择冲突。

### 4. UI 挂在卡片区内层，不做底部上拉

- **选择**：用 `RefreshIndicator` 包裹 `buildCardsBody()` 的可滚子树（list / waterfall / 空态），统一 `AlwaysScrollableScrollPhysics`；header/timeline 保持固定。
- **理由**：与现有布局侵入最小；预测非「最新贴底」流，无需喂养页底部上拉。
- **备选否决**：整页 `CustomScrollView` + timeline 进 sliver — 改动面大；底部上拉 — 明确不做。

### 5. 与 home→range 既有耦合共存

- **选择**：手势仍**显式** force ensure range（保证熔断已重置且不等 debounce）；接受 `refreshFromRemote` 成功后 `scheduleInvalidation` 可能再防抖一轮，由 single-flight / force-after-inflight 收敛。
- **理由**：显式 range 才能保证手势语义与 Toast 可归因；不拆 home 既有失效钩子。

### 6. 副作用 PUT

- **选择**：下拉不调用 `requestPredictImminent*` / `requestPredictActiveEta*`；历史更新后指纹变化再走既有调度。
- **理由**：遵守副作用 HTTP 治理，避免手势绕过 PUT 熔断。

## Risks / Trade-offs

- [双拉 range] home 成功后再 `scheduleInvalidation` → 可能第二轮 ensure → 接受；single-flight 限制并发，手势侧仍只主动发起一轮。
- [失败信号缺失] 现 API 吞错 → 实现时补返回值/标志，避免 Toast 永远不触发或误触发。
- [PageView 横滑] 竖向下拉一般兼容；若边缘冲突，优先保证卡片区垂直手势。
- [未登录/未绑定] 可拉但网络路径可能早退；早退是否算「失败」：无可用 session/deviceNo 时 MAY Toast「请先登录/绑定」或等价，避免假成功转圈结束且无反馈（实现与文案在 tasks 中对齐现网 toast 习惯）。

## Migration Plan

- 纯客户端行为增量；无需数据迁移。
- 回滚：去掉 `RefreshIndicator` 与手势入口即可；熔断 API 保持向后兼容。

## Open Questions

- （无阻塞）冷态骨架是否与热态共用同一 `onRefresh`：倾向共用，失败时同样 Toast。
