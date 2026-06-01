## 1. Repository 与常量

- [x] 1.1 定义 `kHomeHistoryPageSize = 20` 与 `HistoryListPage`（list/total/page/pageSize/hasMore）
- [x] 1.2 `FeedRepository` / `RemoteFeedRepository`：`tryLoadHistoryPage(page, pageSize)`，替换硬编码 50

## 2. Notifier 分页状态

- [x] 2.1 扩展 `HomeHistoryState`：`total`、`highestPageLoaded`、`loadingMore`、`hasMore`
- [x] 2.2 `refreshFromRemote`：page=1，重置分页；`loadMoreHistory`：prepend 去重 + scroll 补偿 hook
- [x] 2.3 `HomeHistoryStore` envelope（items + total + highestPageLoaded）读写

## 3. UI 触发

- [x] 3.1 `HomeHistoryScroll`：`RefreshIndicator`（触顶+hasMore → loadMore，否则 refresh）
- [x] 3.2 加载更多时顶部 loading；prepend 后 `ScrollController` 偏移补偿
- [x] 3.3 `home_screen` 连接 notifier 方法

## 4. 验证

- [x] 4.1 `flutter analyze` 相关文件
- [x] 4.2 手工：首屏 20 条、下拉加载第 2 页、无更多时刷新、滚动不跳动、WS 仍更新
