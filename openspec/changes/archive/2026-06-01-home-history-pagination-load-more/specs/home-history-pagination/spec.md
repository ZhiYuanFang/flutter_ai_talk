## ADDED Requirements

### Requirement: 主页历史分页大小

The client SHALL use **`pageSize=20`** for all home history list HTTP requests unless explicitly overridden by a future spec. 主页历史列表请求 MUST 使用 **`pageSize=20`**（含首次加载、刷新、加载更多）；MUST NOT 再默认使用 50。

#### Scenario: 首次进入主页

- **WHEN** 已登录用户进入主页并触发历史列表 HTTP 拉取
- **THEN** Query MUST 包含 `page=1` 与 `pageSize=20`

#### Scenario: 加载更多

- **WHEN** 客户端请求历史第 2 页及之后
- **THEN** Query MUST 包含对应 `page` 与 `pageSize=20`

### Requirement: 较旧方向加载更多

The client SHALL load additional history pages when the user refreshes or scrolls toward the **older** end of the home history list (top of scroll content when newest is anchored at bottom), and SHALL merge older records into the displayed ascending list. 当用户在历史区向**更旧**方向交互（列表顶部/下拉刷新触顶）且服务端仍有更早数据时，客户端 MUST 请求 **`page+1`**，并将返回记录按升序 **prepend** 到当前列表（按 `id` 去重）；MUST NOT 丢弃已展示条目。

#### Scenario: 仍有更多时加载下一页

- **WHEN** 已加载条数少于服务端 `total` 且用户在下拉刷新时列表已处于顶部（或等价触顶条件）
- **THEN** 客户端 MUST 请求下一页并合并更旧记录，UI MUST 保持滚动位置不发生明显跳变

#### Scenario: 无更多数据

- **WHEN** `page * pageSize >= total` 或等价 `hasMore == false`
- **THEN** 客户端 MUST NOT 再发起加载更多请求；下拉 MAY 回退为刷新第 1 页

#### Scenario: 加载失败

- **WHEN** 加载更多 HTTP 失败
- **THEN** 已展示列表 MUST 保持不变；MAY 展示轻量错误提示

### Requirement: 刷新最新一页

The client SHALL refresh page 1 on explicit pull-to-refresh when not loading more, replacing the in-memory snapshot with the newest page while preserving WebSocket merge rules for subsequent updates. 非「加载更多」的下拉刷新 MUST 重新拉取 **第 1 页**（20 条）并更新「最新一页」快照；WS 推送的 create/update/delete MUST 继续作用于当前内存列表。

#### Scenario: 下拉刷新非触顶加载更多

- **WHEN** 用户下拉刷新且不满足「触顶加载更多」条件，或已无更多页
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并刷新最新数据

### Requirement: 分页元数据

The client MUST parse `total`, `page`, and `pageSize` from the list API response to compute whether more pages exist. 客户端 MUST 解析响应中的 **`total`**（及 `page`/`pageSize`）以计算 **`hasMore`**；不得仅凭当前内存条数猜测是否还有下一页。

#### Scenario: 解析 total

- **WHEN** 列表 API 返回 `code=0` 且 `data.total` 为 120
- **THEN** 在 `pageSize=20` 下客户端 MUST 判定至少存在 6 页数据
