## Context

- API：`GET /device/history/api/list?deviceNo&page&pageSize`；响应 `data.list`（时间倒序）、`total`、`page`、`pageSize`。
- 现网：`RemoteFeedRepository.tryLoadHistory()` 固定 `page=1, pageSize=50`，结果转升序 `_items`。
- UI：`HomeHistoryScroll` 正向滚动，**最新在底部**；较旧记录在**滚动内容顶部**。
- 状态：`HomeHistoryNotifier.refreshFromRemote` 全量替换为第 1 页；WS `upsert`/`remove` 在内存列表上操作。

## Goals / Non-Goals

**Goals:**

- 常量 `kHomeHistoryPageSize = 20`（单处定义，Repository/Notifier 共用）。
- 首次/刷新：拉取第 1 页，升序展示；`hasMore = loadedCount < total`（或 `list.length == pageSize && page*pageSize < total`）。
- **加载更多**：用户在下拉刷新（`RefreshIndicator`，作用于历史 `CustomScrollView`）或滚动至距顶部阈值内时，若 `hasMore && !loadingMore`，请求 `currentPage+1`，将新页转升序后 **prepend** 到现有列表（去重 by `id`）。
- 加载中防重入；失败保留已展示数据。
- 磁盘：冷启动仍优先展示缓存；缓存内容为**当前持久化的升序列表**（首版：每次 `persistToDisk` 写全量已加载项，上限可不做硬 cap，或 cap 200——首版写全量已加载）。

**Non-Goals:**

- 改 WS 协议、趋势页分页、详情 Sheet。
- 双向无限滚动（底部不加载「更新」页，最新仍靠 page1 + WS）。

## Decisions

### 1. pageSize 与 API 封装

```dart
const kHomeHistoryPageSize = 20;

class HistoryListPage {
  final List<HistoryRecord> listDesc; // 服务端顺序
  final int total;
  final int page;
  final int pageSize;
  bool get hasMore => page * pageSize < total;
}
```

`FeedRepository.tryLoadHistoryPage({required int page, int pageSize = kHomeHistoryPageSize})`.

### 2. Notifier 状态

扩展 `HomeHistoryState`：

- `loadedPageCount` 或 `highestPageLoaded`（已请求的最大 page 号，从 1 起）
- `totalCount`（服务端 total）
- `loadingMore` / `refreshing`
- `hasMore` getter

`refreshFromRemote`：请求 page=1，**替换** items 为第 1 页升序，重置 `highestPageLoaded=1`，更新 total。

`loadMoreHistory()`：若 `!hasMore || loadingMore` return；请求 `highestPageLoaded+1`，prepend 升序新条（filter 已存在 id），更新 page/total。

### 3. UI 触发

- **`RefreshIndicator`** 包裹 `CustomScrollView`：`onRefresh` → 若滚动接近顶部则 `loadMoreHistory()`，否则 `refreshFromRemote()` — **简化**：下拉统一先尝试 `loadMoreHistory()` 当 `pixels <= 0` 且 hasMore；若无 hasMore 则 `refreshFromRemote()`。

  更清晰的 UX（采用）：
  - **下拉刷新**：`refreshFromRemote()`（刷新最新 20 条）
  - **滚动至顶部 overscroll / 显式触顶**：自动 `loadMoreHistory()`（`ScrollNotification`：`pixels < 80` 且 `hasMore`）

  用户原文「向下刷新」= **下拉刷新** 在中文产品语境常见；同时要求加载分页 → **下拉时若 hasMore 且已在顶部，加载下一页；否则刷新第 1 页**。或：**下拉 = load more when at top, else refresh**.

  最终方案（兼顾）：
  - 列表**已在顶部**（`scrollOffset <= epsilon`）且 `hasMore`：下拉 → `loadMoreHistory()`
  - 否则下拉 → `refreshFromRemote()`
  - 额外：`ScrollNotification` 滚到顶部附近时自动 prefetch 下一页（可选，首版仅下拉+小 loading indicator）

### 4. 滚动位置

prepend 旧记录后须 **adjust scroll offset** 保持视觉锚点（`ScrollController.jumpTo(oldPixels + deltaHeight)` 或记录 prepend 前首条 context 高度）。`HomeHistoryScrollState` 在 loadMore 完成后由 notifier 通知或使用 `ScrollController` 补偿。

### 5. 磁盘缓存

- 文案从 50 改为 20 指**首屏 API 等价**；`HomeHistoryStore.save` 仍保存当前 memory 全列表（含已 load more 部分），恢复时 `hasMore` 需根据 `items.length` 与 `total` 重算或持久化 `highestPageLoaded`/`total` 到 JSON meta（首版：meta 字段 `_pagination: {total, highestPageLoaded}` 可选；简化为 refresh 时重新 fetch page1 的 total，load more 不持久化 page 号——冷启动只有 cache 条数，hasMore = cache.length < total 需存 total）。

  **Persist**：`HomeHistoryStore` 增加 sidecar 或 envelope `{items, total, highestPageLoaded}`。

## Risks / Trade-offs

- **[Risk] prepend 跳动** → scroll offset 补偿。
- **[Risk] WS 新记录与分页边界** → page1 refresh 合并；WS insert 仍 append。
- **[Trade-off] 首刷重置旧页** → 简单一致；用户需重新上滚加载。

## Migration Plan

- 无数据迁移；旧磁盘 JSON 数组格式可兼容，缺 meta 时 bootstrap 后 `refreshFromRemote` 补 total。

## Open Questions

- （默认）触顶阈值 80px；加载更多 UI 为顶部 `CircularProgressIndicator` sliver。
