## REMOVED Requirements

### Requirement: add 成功后依赖 WebSocket

**Reason**: 按钮路径改为强乐观 UI，必须使用 add 响应 `data.id` 做 pending 替换；列表不再「仅等 WS 才出现行」。

**Migration**: 由 `home-event-optimistic-add` 规约与 `home-event-optimistic-add/design.md` 替代；语音/文字路径仍依赖 WS 插入，但不受本 REMOVED 条约束（见 `home-event-optimistic-add` spec「语音与文字不得乐观插入」）。

## MODIFIED Requirements

### Requirement: 新增历史记录 add 接口

The client SHALL expose `addHistoryEvent` calling **`POST /device/history/api/event/add`** and on success MUST return the server record id parsed from `data.id` in the response envelope. 客户端必须封装 **`POST /device/history/api/event/add`**；请求体 lowerCamelCase，**不得**含 **`eventUnit`**；成功时**必须**解析并返回响应 **`data.id`**（供 UI 替换 pending id），**不得**仅返回无 id 的布尔值。

#### Scenario: 请求体字段

- **WHEN** 发起 add
- **THEN** body 必须至少包含 `deviceNo`、`eventId`、`eventName`、`eventNumber`、`startTime`、`endTime`、`remark`（均为约定类型；时间为 Unix 秒）

#### Scenario: 业务失败

- **WHEN** 响应 envelope `code != 0`
- **THEN** 必须 Toast `message` 并返回失败（无 server id），调用方必须回滚乐观行（若存在）

#### Scenario: 成功返回 id

- **WHEN** 响应 envelope `code == 0` 且 `data.id` 存在
- **THEN** `addHistoryEvent` 必须将 `data.id` 转为字符串 id 返回给调用方

### Requirement: eventType 到 add 载荷映射

The client MUST map catalog `eventType` to add payload as follows. 必须按目录 **`eventType`** 构造 add 体（与废止前一致）：

| eventType | eventNumber | startTime | endTime | remark |
|-----------|-------------|-----------|---------|--------|
| time | 0 | 当前时刻 | 0 | "" |
| one | 1 | 当前时刻 | 当前时刻 | "" |
| number | 用户选择 | 用户选择时刻 | 与 start 相同 | 二级页可选 |

#### Scenario: time 开始计时

- **WHEN** `eventType` 为 `time` 且通过重复校验
- **THEN** `eventNumber` 必须为 0，`endTime` 必须为 0（未结束语义）

#### Scenario: one 一次性

- **WHEN** `eventType` 为 `one`
- **THEN** `eventNumber` 必须为 1，且 `startTime` 与 `endTime` 必须为同一时刻（秒级）

#### Scenario: number 计数

- **WHEN** `eventType` 为 `number` 且用户确认二级页
- **THEN** `eventNumber` 必须为滚轮所选值（5–500），`startTime`/`endTime` 必须为所选时刻
