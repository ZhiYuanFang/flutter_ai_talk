## ADDED Requirements

### Requirement: 历史列表分页查询

The client SHALL load history using **GET** `http://www.cuplay.top:9702/device/history/api/list` (path relative to configurable base) with query parameters **`deviceNo` (string, required for business calls)**, **`page`** starting at **1**, and **`pageSize`** chosen by the client. The server response `data` SHALL follow the agreed shape: `list`, `total`, `page`, `pageSize`; each list item MUST include at least `id`, `deviceNo`, `eventId`, `eventName`, `eventUnit`, `eventNumber`, `startTime`, `endTime`, `remark`, and `action` (array). 列表排序以服务端为准；产品要求为 **时间倒序**，若服务端保证倒序则客户端按返回顺序展示即可。

#### Scenario: 分页请求

- **WHEN** 客户端请求第 2 页且每页 20 条
- **THEN** Query 必须包含 `page=2` 与 `pageSize=20` 以及有效 `deviceNo`

#### Scenario: 解析 list 项

- **WHEN** `code` 为 0 且 `data.list` 非空
- **THEN** 客户端必须将每条记录的 `id` 规范为字符串键用于列表与 WebSocket 合并，并完整保留服务端字段供展示与编辑

### Requirement: 无单条详情拉取

The system SHALL NOT rely on a separate GET-by-id history API; full fields for display and edit MUST come from the list payload (or from WebSocket patch payloads). 历史详情页编辑前数据来自列表项或 WS 推送，不得假设存在 `/history/{id}` 类接口。

#### Scenario: 打开详情编辑

- **WHEN** 用户从列表进入某条历史编辑
- **THEN** 表单初始值必须来自该条列表数据（或已合并的内存态），不得再请求单条详情接口

### Requirement: 历史事件更新

The client SHALL update an event using **POST** `/device/history/api/event/update` with JSON body in **`data` 语义层** containing: `id` (int64), `deviceNo` (string), `eventId` (int64), `eventName`, `eventUnit`, `eventNumber`, `startTime`, `endTime`, `remark`. 全局 **`deviceNo` 必须为 string**，不得使用 int。

#### Scenario: 提交更新

- **WHEN** 用户保存编辑
- **THEN** 客户端必须 POST 上述 path 且 body 字段名与类型符合契约

### Requirement: WebSocket 实时合并历史

The system SHALL use **WebSocket** (not SSE) for server-pushed history changes after updates or other server-side events. Every pushed business record MUST include an **`id`**. The client SHALL search the currently displayed history for the same `id`; if found, the client MUST replace that item in place; if not found, the client MUST treat the item as **new** and insert it according to the product rule for **latest item visibility** (e.g. append and treat as newest for bottom-anchored UI). 未登录 **不得** 建立 WebSocket 连接；无有效 **`deviceNo`** 时 **不得** 建立连接。

#### Scenario: 同 id 更新

- **WHEN** WebSocket 推送一条与列表某条 `id` 相同的数据
- **THEN** 客户端必须在 UI 中更新该条展示为推送内容

#### Scenario: 新 id 插入

- **WHEN** WebSocket 推送一条 `id` 在本地列表中不存在
- **THEN** 客户端必须将该条作为新增记录合并进列表并按「最新一条」产品规则展示

### Requirement: 自然语言指令与回复展示

The client SHALL call **POST** `/voice/text/chat` on the **same API base**, with `data` payload containing **`deviceNo`** and **`transcript`**. The success response `data` MUST be parsed as **`{ "reply": string }`** (inside `data` after envelope unwrap). The UI SHALL show **`reply`** as small text **below the submit/send control**. 未登录 **不得** 调用该接口（拦截见 session spec）。

#### Scenario: 展示 reply

- **WHEN** `code` 为 0 且 `data.reply` 为非空字符串
- **THEN** 客户端必须在发送按钮下方以小字展示该回复内容

#### Scenario: 业务失败

- **WHEN** `code` 非 0
- **THEN** 客户端必须 Toast `message` 且不得将 `reply` 当作成功结果展示
