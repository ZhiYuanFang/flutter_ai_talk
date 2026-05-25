## Why

主页历史目前仅请求 `page=1&pageSize=50` 一次，更早记录无法浏览；首屏拉取 50 条偏重。用户需要在历史区**向较旧方向刷新/滚动**时继续加载后续页，并将默认分页大小改为 **20**，与服务端分页契约一致且更轻量。

## What Changes

- **pageSize 50 → 20**：首次拉取、磁盘缓存快照、日志与文档中对齐 `pageSize=20`。
- **分页加载更多**：在主页历史列表（最新在底部、向上为更旧）当用户**下拉刷新**或滚动至**较旧一端（列表顶部）**时，请求 `page+1`，将更旧记录**合并**到当前升序列表前端；无更多数据时停止并提示或静默。
- **首页刷新语义**：`refreshFromRemote` / bootstrap 仍拉 **第 1 页** 替换「最新一页」快照，并与 WS 增量合并规则兼容；已加载的更旧页在首屏刷新策略上需明确（见 design：首刷重置为第 1 页，清空已加载旧页，或保留——默认**首刷重置**为仅第 1 页，避免 stale 合并）。
- **Repository 层**：`tryLoadHistory` 支持 `page` / `pageSize` 参数，解析 `total`/`page`/`pageSize` 判断 `hasMore`。

## Capabilities

### New Capabilities

- `home-history-pagination`：分页常量、加载更多、hasMore、与 UI 触发（下拉/触顶）。

### Modified Capabilities

- `home-history-disk-cache`（变更 `home-history-disk-cache`）：持久化与首屏等价于 `page=1&pageSize=20`；可选持久化当前已加载全量（design 决策）。
- `history-voice-realtime`（变更 `pangbao-api-liantiao`）：客户端默认 `pageSize=20` 与 load-more 场景。

## Impact

- `app/lib/data/remote_feed_repository.dart`、`feed_repository.dart`
- `app/lib/providers/home_history_notifier.dart` — 分页状态、`loadMoreHistory`
- `app/lib/ui/home_history_scroll.dart` — `RefreshIndicator` / 触顶加载
- `app/lib/ui/home_screen.dart` —  wiring
- `app/lib/data/home_history_store.dart` — 缓存条数说明
- 无后端契约变更（API 已支持 `page`/`pageSize`/`total`）
