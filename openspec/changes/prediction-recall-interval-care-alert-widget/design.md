## Context

当前三条链路相互耦合但门闸不一致：

1. **值得留意**：`predictionCareAlertFetchAllowedProvider` 仅要求 7 日 range 内任意真历史非空；产品要求需有 **Asia/Shanghai 昨日** 发生记录才拉日缓存 API。
2. **预测卡片**：空库走量身定做 Dialog（lastAt + interval）；热态单事件 `prediction == null` 时卡片无 CTA。用户已确认：有 `lastAt` 时 **只选间隔**。
3. **小组件 tip**：`fetchWidgetFeedingTip` 在 `RemoteFeedRepository` 内 `watch` 留意 provider，且只拼 `detailLines`；`resolveWidgetTip` 的 fail-day 会在留意未 ready 时锁死当日重试。v2.1.0 仍规定 tip 走 history chat，本变更 **Breaking** 改为留意派生。

约束：`care-alert` 须 single-flight ensure、provider create 不自动 HTTP；tip sync 须 container.read 避免 notifier 栈内自依赖；回忆种子不得写喂养历史。

## Goals / Non-Goals

**Goals:**

- 共用 **昨日历史门闸** helper（Shanghai 日历日 + `occurrenceInstant`）驱动 care-alert ensure 与 widget tip 是否尝试派生。
- 预测卡 `forecastEnabled && prediction == null && lastAt != null` 展示 CTA + 仅间隔 Sheet → `PredictionRecallSeed` upsert → 行列表即时出现 countdown。
- tip：从留意 state **read** 派生文案（`summaryLine` 优先），移除 fail-day；留意变更后 widget sync 重算 prefs。
- 修复 `remote_feed_repository`：移除异步路径 `watch` 与错误字段拼接。

**Non-Goals:**

- 不改 `event_next_predictor` 算法、不新增后端 API。
- 不恢复预测页底栏 tip 跑马灯（`pause-ucg-vip-slim-prediction-chrome` 仍生效）。
- 不改动空库量身定做 Dialog 的双字段流程。
- 不新建 `**/test/**`。

## Decisions

### D1：昨日门闸 — Asia/Shanghai 自然日

**选择**：新增 `rangeHasShanghaiYesterdayOccurrence(range.items)`，对每条记录 `occurrenceInstant(r, includeActive: true)` 转 UTC+8 日历日与「上海昨日」比较。

**理由**：与 `careAlertShanghaiDayKey`、日缓存 API 同日界一致。

**备选**：本地 `today-1` — 与留意 API 日键可能错位，弃用。

**接入点**：

- `predictionCareAlertFetchAllowedProvider` 替换 `items.isNotEmpty`。
- `_ensureCareAlertOnPredictionVisible` 与现有 listen（gate false→true、历史变非空）复用同一 provider。
- `syncHomeWidgetFromRef` 在 `resolveWidgetTip` 前读同一 gate；未通过则 `tip = null`（不 write fail-day）。

### D2：per-card 间隔 — 复用 recall 原子，不写 lastAt picker

**选择**：在 `_PredictionEventCard` 当 `pred == null && lastAt != null && enabled && onToggle != null` 时展示 `TextButton`/`FilledButton.tonal`「补充大概多久一次」；`showGlassSingleWheelPickerSheet`（与 `prediction_recall_onboarding_panel._pickInterval` 同项表 15min–24h）。

**种子**：`PredictionRecallSeed(rootEventId, lastAt: row.lastAt!, interval, occurrenceAts: synthesizeOccurrenceAts(...))` → `predictionRecallSeedsProvider.notifier.upsertSeed`。

**不触发**：空库 recall Dialog（`predictionRecallEmptyHistoryEligible` 仍为 true 时 Dialog 优先）；demo 骨架卡（`onToggle == null`）。

**lastAt == null**：不展示 CTA（极 rare；有历史但 instant 全失败）。

### D3：tip 派生 — 独立 helper，不走 FeedRepository watch

**选择**：新增 `deriveWidgetTipTextFromCareAlert(List<CareAlertEventItem> items)`：

```
每项：summaryLine 非空 → 用 summaryLine
否则：reasons 的 detailLines 非空行 join
多项：双换行分隔
```

`resolveWidgetTip` 签名改为接受 `Future<String?> Function()` 或直接在 `syncHomeWidgetFromRef` 内 read state 后调用 helper；**删除** `kWidgetTipFailDayKey` 分支与写入。

**缓存策略**：每次 sync 在 gate 通过且 `st.ready && !st.failed` 时重算；与上次 trim 不同则更新 prefs 并 `bumpWidgetTipDisplayEpoch`。保留 `kWidgetTipDayKey` 供陪伴 inject 校验。

**触发 sync**：`ensureLoaded` 成功路径（已有）、`ignoreSuggestion` 本地移除后、`predictionCareAlertStateProvider` ready 且列表变化。

**移除**：`RemoteFeedRepository.fetchWidgetFeedingTip` 中留意 watch；接口可保留为 deprecated 委托 helper 或改 `FeedRepository` 契约由 sync 层读 provider（design 倾向 **sync 层 read，Repository 不再 watch provider**）。

### D4：fail-day 完全删除

**选择**：删除常量、prefs 键、`clearWidgetTipCache` 中对应 remove；空 tip **不** 写任何「当日失败」标记。

**理由**：数据源为本地 read，可随 sync 重复尝试直至留意 ready。

## Risks / Trade-offs

- **[Risk] 今日首录用户无留意无 tip** → 符合产品；per-card 间隔仍可写种子做推演。
- **[Risk] 仅 `detailLines` 的旧实现已部署 fail-day** → 实现时可选一次性 `remove(kWidgetTipFailDayKey)` 迁移。
- **[Risk] tip 与留意 UI 不同步（忽略后）** → ignore 后 `scheduleHomeWidgetSync`。
- **[Risk] Breaking spec vs v2.1.0 chat API** → delta REMOVED + ADDED 在 `widget-tip-from-care-alert`。
- **[Trade-off] 每次 sync 重算 tip** → 成本低；留意列表通常 ≤ 少量条目。

## Migration Plan

1. 实现 `rangeHasShanghaiYesterdayOccurrence` + 更新 fetchAllowed。
2. 实现 `deriveWidgetTipTextFromCareAlert` + 改 `widget_tip_cache` / `home_widget_sync`。
3. 移除 Repository 内 watch；清理 fail-day。
4. 预测卡 CTA + Sheet + seed upsert。
5. 手工：昨日无记录不拉留意；今日有昨日记录拉取成功；忽略后 widget tip 更新；单事件补间隔后出现 countdown。

回滚：恢复 fetchAllowed 为 `items.isNotEmpty`、恢复 chat fetch 与 fail-day（不推荐）。

## Open Questions

- （已闭合）tip 空列表：**隐藏 tip**，不 fallback chat。
- （已闭合）per-card：**仅间隔**，`lastAt` 来自行数据。
