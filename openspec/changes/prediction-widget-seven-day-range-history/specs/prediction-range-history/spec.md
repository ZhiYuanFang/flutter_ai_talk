## ADDED Requirements

### Requirement: Client SHALL load seven-day history via range API into an isolated store

The client SHALL fetch feeding history for the local calendar window from the start of `(today - 6 days)` through `now` using `GET /device/history/api/filter` (empty `eventIds`, `startTime`/`endTime` Unix seconds, `limit` up to 500) and, when a single response is truncated at the limit, MUST continue with `GET /device/history/api/v2/list` for the same window until the window is exhausted or a circuit-break applies. Results MUST be held in a Riverpod store distinct from `homeHistoryProvider`. The client MUST NOT merge this fetch into the feeding home pagination state (`items` / `highestPageLoaded` used by the home history list).

客户端 **必须** 用 range 接口拉取本地近 7 日历史并放入与 `homeHistoryProvider` **隔离** 的 store；触达 filter 上限时 **必须** 用 v2/list 补全；**不得** 写入喂养分页状态。

#### Scenario: 进页拉取 filter

- **WHEN** 预测消费方首次需要近 7 日历史且 range store 未就绪
- **THEN** 客户端 MUST 请求 `GET /device/history/api/filter`（或等价封装）并带上近 7 日 `startTime`/`endTime`
- **AND** MUST NOT 为此调用喂养列表的 `loadNextHistoryPage` / `refreshFromRemote`

#### Scenario: 500 条截断后补页

- **WHEN** filter 返回条数等于约定上限（500）
- **THEN** 客户端 MUST 使用同时间窗的 `GET /device/history/api/v2/list` 继续分页直至无更多或熔断

#### Scenario: 不污染喂养分页

- **WHEN** range 拉取成功
- **THEN** 喂养 `homeHistoryProvider.highestPageLoaded` 与列表 items 深度 MUST NOT 仅因该拉取而被截断或替换为 range 结果

### Requirement: Prediction UI and widget SHALL share the range history store

Smart prediction page rows/charts, the feeding-home prediction tip bar, and desktop widget prediction (`predictAllUpcoming` / equivalent) SHALL read history for prediction from the isolated seven-day range store (not from feeding-home pagination depth). While a range fetch is in flight for that consumer, prediction chart areas that depend on the window MUST show a loading affordance instead of a final empty-window state caused solely by unloaded range data.

预测页、喂养顶栏贴士、桌面小组件预测 **必须** 共用该 7 日 store；range 拉取中图区 **必须** 显示加载中。

#### Scenario: 预测与小组件同源

- **WHEN** range store 已成功加载同一份 7 日列表
- **THEN** 预测页与小组件用于 `predictAllUpcoming` 的 history 输入 MUST 来自该 store（允许各自再叠加 skip / 推演开关过滤）

#### Scenario: 拉取中图区 loading

- **WHEN** 用户在智能预测页且 range 拉取尚未完成
- **THEN** 推演开启事件的折线区域 MUST 显示加载中

### Requirement: Range history fetch SHALL obey side-effect HTTP governance

Ensure/refetch of the seven-day range store triggered by navigation, widget sync, or history mutations MUST use single-flight deduplication, MUST circuit-break after repeated consecutive failures in the same session until logout or explicit retry, and MUST NOT start unbounded automatic retries from Riverpod provider construction alone.

range 拉取 **必须** single-flight、失败熔断，且 **不得** 在 provider 构造时无防护地无限自动重试。

#### Scenario: single-flight

- **WHEN** 预测页与小组件 sync 同时 ensure range
- **THEN** 客户端 MUST 仅运行一个 in-flight range 拉取 Future
- **AND** 后续调用 MUST await 同一 Future

#### Scenario: 历史变更后重拉

- **WHEN** 本地喂养历史因 create/update/delete（含 WS）发生变化
- **THEN** 客户端 MUST 使 range store 失效并 single-flight 重新拉取（MAY 短防抖）
- **AND** MUST NOT 将 range 结果写回喂养分页 items 作为唯一真相源
