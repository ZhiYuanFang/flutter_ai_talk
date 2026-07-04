## ADDED Requirements

### Requirement: Widget history prefetch MUST comply with side-effect HTTP governance

Background history prefetch for home-screen widgets (`ensureWidgetHistoryDepth`) MUST use single-flight deduplication shared with UI `loadMoreHistory`, MUST circuit-break after three consecutive page failures in the same session until logout or explicit retry, and MUST NOT be started from Riverpod provider construction. Successful depth completion SHOULD cache `widgetHistoryDepthReady` to skip redundant prefetch.

小组件历史预拉 MUST 遵守 single-flight、失败熔断，且 MUST NOT 在 provider 构造时自动启动。

#### Scenario: 预拉 single-flight

- **WHEN** 两路代码同时调用 `ensureWidgetHistoryDepth`
- **THEN** 客户端 MUST 仅运行一个 in-flight 预拉 Future
- **AND** 后续调用 MUST await 同一 Future

#### Scenario: 连续三页失败熔断

- **WHEN** 预拉连续 3 次分页 HTTP 失败
- **THEN** 客户端 MUST 停止自动继续预拉直至登出或用户显式重试
- **AND** MUST 使用已有缓存刷新小组件为非 loading 态

#### Scenario: depth ready 跳过重复预拉

- **WHEN** `widgetHistoryDepthReady` 已为 true 且历史未清空
- **THEN** 客户端 MUST NOT 再次自动全量预拉
- **AND** MAY 仍允许用户触顶 loadMore
