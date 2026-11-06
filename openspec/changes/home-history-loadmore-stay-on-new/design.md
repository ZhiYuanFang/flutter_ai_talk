## Context

`HomeHistoryScroll._handleLoadMore` 在 `await onLoadMore` 后用 post-frame `jumpTo(savedPixels + ΔmaxScrollExtent)` 把视口钉回加载前记录。prepend 后首帧 `pixels≈0` 会先露出新页，下一帧再拽回 → 双跳。产品锁定 **A：留在新数据窗口**。

## Goals / Non-Goals

**Goals:**

- 触顶 loadMore 成功后视口留在更旧端（用户继续看到刚合并的更旧记录）。
- 移除（或永久禁用）原位置 `jumpTo` 补偿，消除第二跳。
- 规格与实现一致：禁止「先新页再拽回」。

**Non-Goals:**

- 不做方案 B（无闪同步锚回原记录）。
- 不改分页 API、`pageSize`、merge/去重、底部上拉刷新、`followLatest` 跟底语义。
- 不改吸顶汇总测高（与本双跳根因无关；A 下测高二次长高顶多微调顶区，不再被补偿放大成「弹回原位」）。

## Decisions

1. **删除 loadMore 后的 scroll 补偿**  
   在 `_handleLoadMore` 去掉 `beforeMax` / `beforePixels` 记录与 post-frame `jumpTo(savedPixels + delta)`。`await onLoadMore!()` 后直接返回即可。  
   备选：保留补偿但加开关——无产品需求，增加死代码；放弃。

2. **依赖自然 scroll 行为**  
   正向列表顶=旧：prepend 后若仍近顶，框架保持近 `pixels≈0` → 新页自然可见。  
   `didUpdateWidget` 对 prepend 已跳过 `scrollToBottom`；保持该守卫，避免误跟底。

3. **规格改写**  
   `home-history-pagination`「较旧方向加载更多」场景由「保持滚动位置」改为「留在更旧端 / 不得事后补偿拽回」。

## Risks / Trade-offs

- [原记录滚出视口] → 产品接受：下拉目的就是看更早。  
- [短列表误跟底] → prepend 守卫已有；若仍贴底属既有问题，另案。  
- [吸顶 extent 变化微调顶区] → A 下可接受；勿再引入补偿。

## Migration Plan

1. 删 `_handleLoadMore` 补偿 → 更新 pagination spec。  
2. 手工：触顶下拉 loadMore → 停在新 20 条窗口，不再弹回。  
3. 回滚：恢复 `jumpTo(saved + delta)`（会回到双跳）。

## Open Questions

- （已定）A：留新页，禁拽回。
