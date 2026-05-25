## MODIFIED Requirements

### Requirement: 历史列表分页查询

The client SHALL load history using **GET** `/device/history/api/list` with query parameters **`deviceNo`**, **`page`** starting at **1**, and **`pageSize` defaulting to 20** for the home history surface. The server response `data` SHALL follow the agreed shape: `list`, `total`, `page`, `pageSize`. 主页历史 surface MUST 默认 **`pageSize=20`**；加载更多 MUST 递增 `page`；排序以服务端为准（倒序返回，客户端转升序展示）。

#### Scenario: 分页请求

- **WHEN** 客户端请求第 2 页且每页 20 条
- **THEN** Query 必须包含 `page=2` 与 `pageSize=20` 以及有效 `deviceNo`

#### Scenario: 解析 list 项

- **WHEN** `code` 为 0 且 `data.list` 非空
- **THEN** 客户端必须将每条记录的 `id` 规范为字符串键用于列表与 WebSocket 合并，并完整保留服务端字段供展示与编辑
