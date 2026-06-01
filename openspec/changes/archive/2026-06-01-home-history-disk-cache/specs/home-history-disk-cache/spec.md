## ADDED Requirements

### Requirement: 按 deviceNo 持久化主页历史列表

The system SHALL persist the home history list (first page, up to 50 records) to local storage keyed by `deviceNo`, and SHALL restore it on subsequent launches when the user is logged in with the same `deviceNo`. 系统必须将主页历史列表（与现网 `page=1&pageSize=50` 等价）按 **`deviceNo`** 持久化到本地；用户已登录且 `deviceNo` 有效时，下次进入必须能恢复该宝宝的上次列表快照。

#### Scenario: 冷启动有缓存

- **WHEN** 用户已登录、本地存在该 `deviceNo` 的历史 JSON 且进入主页
- **THEN** 必须在网络请求完成前用缓存数据渲染历史列表（升序 `_items` 规则与现网一致）

#### Scenario: 无 deviceNo

- **WHEN** 用户未登录或 `deviceNo` 为空
- **THEN** 不得读取或写入历史磁盘缓存；列表保持空或当前内存态

### Requirement: stale-while-revalidate 异步刷新

The home screen MUST load cached history first and asynchronously fetch the latest list from `GET /device/history/api/list`; when the remote snapshot differs from cache, it MUST overwrite local storage and update the UI. 主页必须先展示缓存，再异步请求 **`GET /device/history/api/list`**；远端快照与本地不一致时必须覆盖磁盘并刷新 UI；一致时必须避免多余 UI 重绘。

#### Scenario: 远端有更新

- **WHEN** 缓存已展示且远端返回的记录集与本地快照不等价
- **THEN** 必须用远端数据更新 `_items` 并持久化新快照

#### Scenario: 远端无变化

- **WHEN** 远端返回与本地快照等价
- **THEN** 不得因刷新 alone 触发可见列表闪动（允许 no-op setState 以外的稳定展示）

#### Scenario: 远端失败有缓存

- **WHEN** 异步刷新失败但本地有有效缓存
- **THEN** 必须继续展示缓存内容，不得清空列表

### Requirement: 实时变更回写缓存

After WebSocket/SSE merges or a successful local history update on the home screen, the system SHALL persist the current in-memory home list to disk for the active `deviceNo`. 主页因 **WebSocket/SSE** 或 **本地 update/stop** 改变 `_items` 后，必须将当前内存列表写回该 `deviceNo` 的磁盘缓存，以保证下次冷启动一致。

#### Scenario: WS 推送新记录

- **WHEN** `watchLatest` 合并新记录进 `_items`
- **THEN** 必须异步更新磁盘缓存

#### Scenario: 停止计时成功

- **WHEN** 用户在主页成功停止进行中计时并更新 `_items`
- **THEN** 必须异步更新磁盘缓存
