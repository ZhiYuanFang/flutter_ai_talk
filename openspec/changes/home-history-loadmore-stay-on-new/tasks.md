## 1. 去掉 loadMore 滚回补偿

- [x] 1.1 在 `home_history_scroll.dart` 的 `_handleLoadMore` 移除 `beforeMax` / `beforePixels` 与 post-frame `jumpTo(savedPixels + delta)`；保留 `await onLoadMore`
- [x] 1.2 确认 prepend 路径仍跳过 `didUpdateWidget` 的 `scrollToBottom`（避免误跟底）

## 2. 验收

- [ ] 2.1 手工：触顶下拉 loadMore → 停在新合并的更旧记录窗口，不再弹回加载前位置
- [x] 2.2 不新建 `**/test/**`
