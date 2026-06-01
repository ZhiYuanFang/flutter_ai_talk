## ADDED Requirements

### Requirement: 新增历史记录 add 接口

The client SHALL expose `addHistoryEvent` (or equivalent) calling **`POST /device/history/api/event/add`** with lowerCamelCase JSON and MUST NOT include deprecated field **`eventUnit`**. 客户端必须封装 **`POST /device/history/api/event/add`**；请求体使用 lowerCamelCase，**不得**包含 **`eventUnit`**。

#### Scenario: 请求体字段

- **WHEN** 发起 add
- **THEN** body 必须至少包含 `deviceNo`、`eventId`、`eventName`、`eventNumber`、`startTime`、`endTime`、`remark`（均为约定类型；时间为 Unix 秒）

#### Scenario: 业务失败

- **WHEN** 响应 envelope `code != 0`
- **THEN** 必须 Toast `message` 并返回失败，不得将记录视为已创建

### Requirement: eventType 到 add 载荷映射

The client MUST map catalog `eventType` to add payload as follows. 必须按目录 **`eventType`** 构造 add 体：

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

### Requirement: add 成功后依赖 WebSocket

The system SHALL rely on the existing history WebSocket push to update the home list after add; the client MUST NOT require using the add response record id for UI insertion. add 成功后**必须**依赖既有历史 **WebSocket** 更新列表；**不得**要求用响应中的新记录 `id` 手动插入 UI。

#### Scenario: WS create 推送

- **WHEN** add 成功且 WS 推送 `create`/`update`
- **THEN** 主页历史列表必须按既有合并规则展示新记录

## ADDED Requirements

### Requirement: 历史 update 不再发送 eventUnit

The client MUST remove `eventUnit` from `POST /device/history/api/event/update` request bodies built by `buildEventUpdateBody`. 客户端构造 **`event/update`** 请求体时**不得**再包含 **`eventUnit`** 字段。

#### Scenario: 停止计时或详情保存

- **WHEN** 调用 `updateHistoryRecord`
- **THEN** JSON body 不得含 `eventUnit` 键
