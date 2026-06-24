## ADDED Requirements

### Requirement: 底部上拉 SHALL 刷新最新一页

When the user is near the **bottom** of the home history scroll view (newest records) and performs an upward pull gesture that exceeds a minimum threshold before release, the client MUST invoke the same refresh path as explicit pull-to-refresh for page 1 (`refreshFromRemote` / `GET /device/history/api/list?page=1&pageSize=20`). The bottom pull gesture MUST NOT trigger `loadMoreHistory`. The client MUST NOT refresh on bottom pull when the user is not near the bottom or when the accumulated pull distance is below the threshold.

当用户处于主页历史列表**底部附近**（最新记录在底部）并上拉超过最小阈值后松手，客户端**必须**调用与「刷新最新一页」相同的路径（`refreshFromRemote`，请求 page=1）；**不得**触发 `loadMoreHistory`。未近底或上拉距离未达阈值时**不得**刷新。

#### Scenario: 底部上拉超过阈值并松手

- **WHEN** 列表已滚动至底部附近且用户上拉累积距离达到实现定义的最小阈值（建议约 72 logical px）后松手
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并更新最新喂养记录
- **AND** 刷新完成后视口 SHOULD 锚定在最新记录（底端）

#### Scenario: 上拉未达阈值

- **WHEN** 用户在底部附近上拉但未达到阈值即松手
- **THEN** 客户端 MUST NOT 发起 refresh HTTP 请求

#### Scenario: 非底部区域上拉

- **WHEN** 用户不在列表底部附近（未满足近底判定）时拖动
- **THEN** 客户端 MUST NOT 因该手势触发 refreshFromRemote

#### Scenario: 底部上拉不得加载更旧页

- **WHEN** 用户在底部附近完成上拉刷新
- **THEN** 客户端 MUST NOT 调用 `loadMoreHistory` 或请求 `page>1` 作为该手势的响应

#### Scenario: 刷新进行中忽略重复手势

- **WHEN** 底部 refresh 已在 in-flight 且用户再次上拉
- **THEN** 客户端 MUST NOT 并发发起第二次 page=1 请求（与现有 `_refreshFuture` 合并语义一致）

## MODIFIED Requirements

### Requirement: 刷新最新一页

The client SHALL refresh page 1 on explicit pull-to-refresh when not loading more, **or** when the user completes a bottom upward-pull refresh per the bottom-pull requirement, replacing the in-memory snapshot with the newest page while preserving WebSocket merge rules for subsequent updates. 非「加载更多」的**顶部下拉**刷新，或符合「底部上拉刷新」条件的交互，MUST 重新拉取 **第 1 页**（20 条）并更新「最新一页」快照；WS 推送的 create/update/delete MUST 继续作用于当前内存列表。

#### Scenario: 下拉刷新非触顶加载更多

- **WHEN** 用户在列表**顶部**下拉刷新且不满足「触顶加载更多」条件，或已无更多页
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并刷新最新数据

#### Scenario: 底部上拉刷新最新

- **WHEN** 用户按「底部上拉 SHALL 刷新最新一页」完成有效上拉刷新
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并刷新最新数据
- **AND** 行为 MUST 与顶部非 loadMore 的 refresh 使用同一 `refreshFromRemote` 实现
