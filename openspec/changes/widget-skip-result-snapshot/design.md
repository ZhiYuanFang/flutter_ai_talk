## Context

- 前台 `syncHomeWidgetFromRef` → `resolveWidgetPredictionInputs` 使用 `predictionRealHistoryProvider`（range∪home）+ recall + forecast disabled，`buildHomeWidgetPayload` 以 `count: 6` 填 `recentLast`。
- 后台 `homeWidgetInteractiveCallback` → `applyWidgetHeroSkipAndRefresh` 无 Riverpod，当前读 `HomeHistoryStore.loadSnapshot` 后裸 `predictAllUpcoming`，可预测根变少 → large 第二行消失（6→3）。
- Android / iOS native 仅按 payload 长度裁切（large `maxSlots`/`prefix(6)`）；两端触发同一 Dart 回调。
- `widget-prediction-range-parity` 已对齐前台 sync，design 将 hero skip 标为 Non-Goal，留下本缺口。
- 方案 B（用户选定）：缓存**预测结果**供 skip，而非在后台重建 range 输入（方案 A）。

## Goals / Non-Goals

**Goals:**

- 前台成功写出 widget payload 时同步持久化预测结果快照（后台 isolate 可读）。
- 桌面「跳过」用快照 + `WidgetHeroSkipStore` 重建 hero / `recentLast`，保持 large 预算深度。
- 单一 Dart 路径同时修复 Android 与 iOS；S1 skip 语义不变（仅 hero 排除 skip，`recentLast` 仍可含已 skip id）。

**Non-Goals:**

- 不在后台 isolate 拉 HTTP / 建 Riverpod / 重算 7 日 range。
- 不改 native 布局 XML / SwiftUI 槽位上限（仍 large=6、medium=3）。
- 不把本 change 升级为完整「输入快照 / range 落盘」（方案 A）。
- 不新建 `**/test/**`。
- 不改 tip / medium 无跳过等既有产品规则。

## Decisions

### 1. 快照内容：有序预测行，而非完整 HistoryRecord 列表

前台在 `buildHomeWidgetPayload`（或紧随其后、仍持有完整 `predictions` 处）将**已算好的** `EventNextPrediction` 序列（或等价 wire：`eventId`、`nextAt`、`lastAt`、名称/色等重建 hero/`recentLast` 所需字段）写入独立键（建议 `widgetPredictionSnapshot`），条数至少覆盖 large：hero 候选 + `recentLast` 最多 6（实现可存完整预测列表截断到合理上限，如 16，避免过大）。

**理由**：skip 只需「换 hero + 重排 recent」，不必再跑 `predictAllUpcoming`。  
**备选**：只存上一份 payload 的 hero+recentLast 并做列表晋升——拒为唯一方案（缺完整排序时难填满 6，且与「按 nextAt 全局序」弱一致）；可作为快照缺失降级。

### 2. 写入时机：与成功 `pushHomeWidgetPayload` 同源成功路径

凡前台 `scheduleHomeWidgetSync` / `syncHomeWidgetFromRef` 成功推送 ready payload 时 MUST 写快照。登出 / empty payload MUST 清除或覆盖为空快照，避免串用户。

**理由**：快照与用户可见桌面内容同代。  
**备选**：仅在 App 进前台写——拒，会漏掉 range ready 后无 UI 的 sync。

### 3. 存储介质：后台回调已用的 prefs / HomeWidget App Group

复用 `SharedPreferences` 与/或 `HomeWidget.saveWidgetData`（与 payload 同 App Group），保证 `@pragma('vm:entry-point')` 回调在 `setAppGroupId` 后可读。键名写入 `home_widget_constants.dart`（或邻近常量）。

**理由**：与现有 skip / payload 路径一致，无新依赖。  
**备选**：仅 Documents 文件——可行但多一套 I/O；非必须。

### 4. Skip 重建算法（方案 B 主路径）

```
applyWidgetHeroSkipAndRefresh(eventId):
  1. 解析 deviceNo；无则 abort
  2. 从快照取有序 predictions（或 wire 行）
  3. 用快照中该 event 的 lastAt（无则 now）写 WidgetHeroSkipStore.skipEvent
  4. reconcile + filterPredictionsExcludingSkipped → heroPredictions
  5. buildWidgetHero + buildWidgetRecentLast(count: 6)（recent 用未滤 skip 的全序，与现 payload 规则一致：仅 hero 排除 skip）
  6. 保留 visual/header/tip 策略：优先读上一份 payload；catalog enrich 可用 EventCatalogStore.loadFromDisk
  7. pushHomeWidgetPayload
```

**禁止**：默认成功路径调用 `HomeHistoryStore` + 裸 `predictAllUpcoming`。

**降级**（快照空/损坏）：

1. 优先：读上一份 `HomeWidgetPayload`，将当前 hero 标 skip 后从 `recentLast` 晋升下一条为 hero，其余 recent 保持（槽位数不塌）。
2. 再不行：写无预测文案 / 保留旧 payload + 日志 `AppDebugLog.homeWidget`，**不得**静默用浅分页重算当作「修复成功」。

### 5. 双端策略

不修改 Android `PangbaoWidgetRenderer` / iOS `PangbaoWidget.swift` 的槽位裁切；修复完全在 Dart。两端手工验收 large 跳过。

**理由**：根因跨平台同源。  
**备选**：native 硬编码「至少画 6 空槽」——拒，会显示空壳且掩盖数据问题。

### 6. 与 range-parity 的关系

前台仍按 parity 算预测并写快照；skip 消费快照，不要求后台读 range store。下次前台 sync 用新鲜 range∪recall 覆盖快照与 payload。

## Risks / Trade-offs

- **[Risk] 跳过后 nextAt 略 stale，直到下次前台 sync** → 可接受（方案 B 取舍）；进 App / 历史变更仍会 sync。
- **[Risk] 旧安装无快照，首次跳过走降级** → 降级用现有 payload 晋升保槽位；随后一次前台 sync 写满快照。
- **[Risk] 快照与 skip 基线 lastAt 不准导致 reconcile 异常** → 快照须带 `lastAt`；缺失时用 payload hero / now 并打日志。
- **[Trade-off] 不解决「从未前台 sync 过就冷启点跳过」的深度预测** → Non-Goal；冷启应先 loading→ready sync。

## Migration Plan

1. 新增快照读写模块/函数与常量键。
2. 前台 sync 成功路径写快照；登出清快照。
3. 改写 `applyWidgetHeroSkipAndRefresh` 走快照 + 降级。
4. Android + iOS 手工：large 跳过仍约 6 格；hero 换下一条；medium 仍 ≤3。
5. 回滚：恢复旧 skip 函数即可（行为退回 6→3 bug）。

## Open Questions

- 无。快照键放 SharedPreferences 还是 HomeWidget data 由实现择一或双写，以后台可读为准。
