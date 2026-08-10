## MODIFIED Requirements

### Requirement: Widget history prefetch MUST comply with side-effect HTTP governance

Background history fetch for home-screen widget prediction (seven-day range ensure, replacing `ensureWidgetHistoryDepth` page loops over `loadMoreHistory`) MUST use single-flight deduplication shared with other range-history consumers (e.g. smart prediction page), MUST circuit-break after three consecutive range HTTP failures in the same session until logout or explicit retry, and MUST NOT be started from Riverpod provider construction without an idempotent guarded starter. Successful range readiness SHOULD cache `widgetHistoryDepthReady` (or equivalent) to skip redundant full range prefetch until history invalidation or logout.

小组件预测用历史拉取 **必须** 走 7 日 range、与预测页共享 single-flight，遵守失败熔断；**不得** 再与 UI `loadMoreHistory` 共用分页预拉；**不得** 在 provider 构造时无防护启动。

#### Scenario: range 预拉 single-flight

- **WHEN** 两路代码同时 ensure 七日报 range 历史
- **THEN** 客户端 MUST 仅运行一个 in-flight range Future
- **AND** 后续调用 MUST await 同一 Future

#### Scenario: 连续失败熔断

- **WHEN** range 拉取连续 3 次 HTTP 失败
- **THEN** 客户端 MUST 停止自动继续 range 预拉直至登出或用户显式重试
- **AND** MUST 使用已有缓存刷新小组件为非 loading 态

#### Scenario: ready 跳过重复全量预拉

- **WHEN** range ready / `widgetHistoryDepthReady` 已为 true 且未被历史变更失效
- **THEN** 客户端 MUST NOT 再次自动全量 range 预拉
- **AND** MAY 仍允许喂养页用户触顶 loadMore（仅影响喂养列表）
