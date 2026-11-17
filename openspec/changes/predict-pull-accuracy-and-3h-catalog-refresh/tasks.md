## 1. 下拉准确率对齐

- [x] 1.1 `onCardsPullRefresh`：滚动历史成功后调度 `schedulePredictPostHistoryMutation`
- [x] 1.2 确认不 await 整趟 expect-batch；失败 Toast 路径不强制调度
- [x] 1.3 手动验：服务端已有今日 expect、下拉前无柱 → 下拉后真柱出现（或管线回写后出现）

## 2. 三小时功能包 force

- [x] 2.1 `_NextThreeHoursTimeline` onTap：`featureCatalog.refresh()` / `ensureLoaded(force: true)` 与开墙并行
- [x] 2.2 syncing 仍不可点；catalog 失败仍开墙用旧 cache
- [x] 2.3 手动验：改 catalog 文案后点三小时，墙内可见新内容（或至少发起 force 请求）
