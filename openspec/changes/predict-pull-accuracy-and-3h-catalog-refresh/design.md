## Context

预测下拉现：`refreshRollingWindow` + 预约 next/last。准确率读 `homeHistory.items` 的已存 `expect*`；expect-batch 成功后主要靠 WS upsert 回本地，滞后时柱空白。三小时卡开墙只预热 Pro 资格与想法，catalog 为进页 cache-first `ensureLoaded()`。

基线：`smart-prediction-page`、`predict-list-accuracy-bars`、`predict-post-mutation-scheduler`（v2.2.1）。叠在 sample-global-gate / leaf-identity 之上。

## Goals / Non-Goals

**Goals:**

- 下拉成功后调度静默 expect 管线，推动准确率样本对齐。
- 点三小时开墙时 force 拉功能包 catalog。

**Non-Goals:**

- 不做 expect 乐观本地写入（另案）；不改示例门闩；不改墙内 CTA/支付。

## Decisions

1. **下拉准确率对齐**  
   `onCardsPullRefresh`：先 `await refreshRollingWindow`（及预约 silent）；**成功后**（homeOk）`unawaited(schedulePredictPostHistoryMutation(ref))`（或等价）。失败 Toast 路径不强制调度。管线仍 single-flight / dirty；下拉不 await 完整 batch（避免 RefreshIndicator 挂太久），但 MUST 已入队。

2. **为何调度 batch 而非仅 rolling**  
   Rolling 只能带回服务端已有 expect；调度可补打漏戳并经 WS/后续合并刷新柱。与「刷新带上准确率」产品语义一致。

3. **三小时 catalog**  
   `onTap`：`unawaited(featureCatalogStateProvider.notifier.refresh())` **与** `showPredictCapabilityTierWall` 并行（先 fire refresh 再开墙，或同帧两者）。MUST NOT 等 catalog HTTP 成功才开墙（失败保留旧 items）。syncing 仍不可开墙，亦不必 force。

4. **副作用 HTTP**  
   catalog force / expect 管线遵守既有 single-flight、熔断、失败保留旧态。

## Risks / Trade-offs

- [下拉后 batch 仍慢，柱晚一拍] → 可接受；比纯 rolling 更完整。  
- [每次点三小时都打 catalog] → 产品要新鲜功能包；notifier force + circuit 已有。  
- [RefreshIndicator 与 batch 竞态] → 不 await batch；rolling 先落盘。

## Open Questions

- （已定）一个提案含下拉准确率对齐 + 三小时功能包 force。
