## MODIFIED Requirements

### Requirement: Widget history depth prefetch SHALL load older pages in background

When the home-screen widget needs history for prediction and the isolated seven-day range store is not ready, the client SHALL ensure that store via the range history API (`GET /device/history/api/filter` and, if truncated, `GET /device/history/api/v2/list` for the same local window spanning from the start of `(today - 6 days)` through `now`). The client MUST NOT prefetch widget prediction history by paging feeding-home `loadMoreHistory` until 30 local calendar days. On successful range readiness the client MUST set (or treat as) `widgetHistoryDepthReady` / equivalent ready flag and refresh the widget payload. Prefetch MUST NOT merge into feeding-home pagination state.

小组件预测所需历史 **必须** 经近 7 日 range store/接口拉取；**不得** 再经喂养 `loadMoreHistory` 预拉至 30 日；成功后 **必须** 标记 ready 并刷新小组件 payload。

#### Scenario: 预拉至 7 日 range

- **WHEN** 小组件需要预测且 range store 未就绪
- **THEN** 客户端 MUST 发起近 7 日 range 拉取（single-flight）
- **AND** MUST NOT 以「跨满 30 自然日」为停止条件去请求喂养更旧分页

#### Scenario: 与喂养 UI loadMore 隔离

- **WHEN** 用户触顶 loadMore 与小组件 range ensure 同时触发
- **THEN** 客户端 MUST NOT 将二者合并为同一喂养分页请求序列
- **AND** range 拉取 MUST 使用独立 in-flight（可与预测页共享 range Future）

#### Scenario: 预拉超时或熔断 fallback

- **WHEN** range 拉取超时或熔断仍未完整成功
- **THEN** 客户端 MUST 使用已有 range/喂养缓存尽力计算预测
- **AND** MUST 退出小组件 loading 态
