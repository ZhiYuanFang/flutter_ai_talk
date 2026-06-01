## MODIFIED Requirements

### Requirement: 按 deviceNo 持久化主页历史列表

The system SHALL persist the home history list (first page equivalent: **`page=1&pageSize=20`**, plus any additionally loaded older pages currently in memory) to local storage keyed by `deviceNo`, and SHALL restore it on subsequent launches when the user is logged in with the same `deviceNo`. 系统必须将主页历史列表（首屏等价 **`page=1&pageSize=20`**，以及内存中已通过分页加载的更旧记录）按 **`deviceNo`** 持久化；用户已登录且 `deviceNo` 有效时，下次进入必须能恢复上次列表快照（含分页元数据如 `total` / 已加载页数，若实现采用 envelope）。

#### Scenario: 冷启动有缓存

- **WHEN** 用户已登录、本地存在该 `deviceNo` 的历史 JSON 且进入主页
- **THEN** 必须在网络请求完成前用缓存数据渲染历史列表（升序 `_items` 规则与现网一致）

#### Scenario: 无 deviceNo

- **WHEN** 用户未登录或 `deviceNo` 为空
- **THEN** 不得读取或写入历史磁盘缓存；列表保持空或当前内存态

### Requirement: stale-while-revalidate 异步刷新

The home screen MUST load cached history first and asynchronously fetch the latest list from `GET /device/history/api/list` with **`page=1&pageSize=20`**; when the remote snapshot differs from cache, it MUST overwrite local storage and update the UI. 主页必须先展示缓存，再异步请求 **`GET /device/history/api/list`（`page=1&pageSize=20`）**；远端快照与本地不一致时必须覆盖磁盘并刷新 UI；一致时必须避免多余 UI 重绘。

#### Scenario: 远端有更新

- **WHEN** 缓存已展示且远端第 1 页与本地快照不等价
- **THEN** 必须用远端第 1 页数据更新列表并持久化（已加载的更旧分页是否保留由分页 spec 约束；首刷默认重置为仅第 1 页时 MUST 清除仅存在于旧分页的条目）

#### Scenario: 远端无变化

- **WHEN** 远端返回与本地快照等价
- **THEN** 不得因刷新 alone 触发可见列表闪动（允许 no-op setState 以外的稳定展示）

#### Scenario: 远端失败有缓存

- **WHEN** 异步刷新失败但本地有有效缓存
- **THEN** 必须继续展示缓存内容，不得清空列表
