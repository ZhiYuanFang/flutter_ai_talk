## ADDED Requirements

### Requirement: Widget history depth prefetch SHALL load older pages in background

When home-screen widget is first enabled and local history depth is insufficient for prediction, the client SHALL prefetch older history pages in the background using the same `loadMoreHistory` merge and persist path as UI pagination. Prefetch MUST stop when any of: cached history spans at least 30 local calendar days from oldest record to now, 15 pages loaded, or `hasMore == false`. On completion the client MUST set a persistent `widgetHistoryDepthReady` flag and refresh the widget payload.

小组件首次启用时 MUST 后台预拉历史直至满足 30 天 / 15 页 / 无更多之一，并 MUST 持久化 depth-ready 标记。

#### Scenario: 预拉至 30 天

- **WHEN** 本地最早记录距今已达 30 个自然日且预拉 in-flight
- **THEN** 客户端 MUST 停止继续请求更旧页
- **AND** MUST 标记 depth ready 并刷新小组件

#### Scenario: 与 UI loadMore 共用合并

- **WHEN** 用户触顶 loadMore 与 widget 预拉同时触发
- **THEN** 客户端 MUST single-flight 合并为一次分页请求序列
- **AND** MUST NOT 并行重复请求同一 page

#### Scenario: 预拉超时 fallback

- **WHEN** 预拉持续超过 30 秒仍未完成
- **THEN** 客户端 MUST 使用已有缓存尽力计算预测
- **AND** MUST 退出 loading 态
