## ADDED Requirements

### Requirement: Client MUST recognize appointment events from catalog

The client MUST parse `isAppointment` from event options (or equivalent catalog payload). When the field is missing or zero/false, the event MUST be treated as non-appointment. The client MUST NOT infer appointment solely from `eventType=one`. Appointment read/write, prediction nodes, and pending sync MUST use the catalog **root** `eventId`. 客户端 **必须** 从事件 options 解析 `isAppointment`；缺失或假值 **必须** 视为非预约；**不得** 仅因 `eventType=one` 判定为预约；预约相关读写与同步 **必须** 使用根 eventId。

#### Scenario: Options marks vaccine as appointment

- **WHEN** options 某事件 `isAppointment` 为真（如 `1`）
- **THEN** 客户端 MUST 将该事件按预约事件处理（预测与编辑分流）

#### Scenario: Missing field defaults non-appointment

- **WHEN** options 项无 `isAppointment` 字段
- **THEN** 客户端 MUST 按非预约事件处理

#### Scenario: Child flag resolves to root id

- **WHEN** 子事件带 `isAppointment` 且存在 catalog 根
- **THEN** 客户端 MUST 以根 eventId 调用预约 API 并纳入预测/pending

### Requirement: Appointment prediction card MUST use next trigger time not interval

For appointment events on the smart prediction surface, the client MUST NOT present the per-card 「补充大概多久一次」 flow. The client MUST present 「补充下次」 (or equivalent) that opens the dedicated next-appointment sheet. Cards with no stored nextAt MUST still be shown when other prediction-card rules allow, without emitting a pushable pending node. 预约事件预测卡 **不得** 走间隔补充；**必须** 以「补充下次」打开专用 sheet；无约定卡在可展示时仍展示且 **不得** 产生可推送节点。

#### Scenario: Appointment card opens next-time sheet

- **WHEN** 用户在预约预测卡上发起「补充下次」
- **THEN** 客户端 MUST 打开专用下一次预约 sheet，MUST NOT 打开间隔 picker 作为默认补充 UI

#### Scenario: No nextAt card visible without pending

- **WHEN** 预约事件 `nextAt=0` 且该根事件预测卡按目录规则可见
- **THEN** 卡 MUST 可展示并提供「补充下次」，且 MUST NOT 将该事件以正 nextAt 写入 pending

### Requirement: Appointment events MUST NOT use interval-sample prediction

When `isAppointment` is true, the client MUST NOT compute next occurrence via the interval-sample predictor. If a stored `nextAt>0` exists for the root `(deviceNo, eventId)`, that instant MUST be the prediction result even when it is in the past (UI MUST mark overdue; pending MUST still include it). If `nextAt==0` or absent, the client MUST NOT emit a pushable prediction node for that event. 预约事件 **不得** 用间隔样本推演；有约定（含过期）则以为预测结果并仍可推送；无约定则 **不得** 产生可推送节点。

#### Scenario: User-set nextAt becomes prediction

- **WHEN** 预约事件已持久化 `nextAt=T`（T>0）
- **THEN** 该事件预测结果 MUST 为时间 T

#### Scenario: Overdue nextAt still pushable

- **WHEN** 预约事件 `nextAt=T>0` 且 T 早于当前时间
- **THEN** UI MUST 标过期，且 pending MUST 仍包含该 eventId 与 T

#### Scenario: No nextAt means no pending node

- **WHEN** 预约事件 `nextAt=0`
- **THEN** 客户端 MUST NOT 将该事件以正 `nextAt` 写入 predict-imminent pending 列表

### Requirement: Client MUST sync appointment nextAt via dedicated API

The client MUST read and write next trigger time through `GET`/`PUT /device/app/api/appointment/next` with `deviceNo` and root `eventId`, independent of history CRUD. `nextAt=0` MUST mean no appointment. Editing any history row of the same root MUST show the same nextAt. 客户端 **必须** 经独立预约 API 读写下次约定；与 history 解耦；`0` 表示无约定；同根任意历史行回填相同。

#### Scenario: Edit sheet loads server nextAt

- **WHEN** 用户打开某预约事件的编辑 sheet（无论点哪条 history）
- **THEN** 客户端 MUST GET 该根 `(deviceNo, eventId)` 的 nextAt 并显示

#### Scenario: Edit sheet tap to modify

- **WHEN** 用户在编辑页点击下次预约时间
- **THEN** 客户端 MUST 打开专用下一次预约 sheet 供修改

### Requirement: Clear appointment MUST be edit-sheet only

The client MUST provide clear-appointment (`PUT nextAt=0` then pending omit) **only** on the history edit surface. The dedicated next-appointment sheet used after add/supplement or from the prediction card MUST NOT offer clear. 清空预约 **必须** 仅在编辑 history 页提供；打点后/预测卡专用 sheet **不得** 提供清空。

#### Scenario: Clear from edit sheet

- **WHEN** 用户在编辑页清空下次约定
- **THEN** 客户端 MUST PUT `nextAt=0`，且 MUST 在随后的 pending 同步中移除该根 eventId

#### Scenario: Dedicated sheet has no clear

- **WHEN** 用户打开专用下一次预约 sheet（新增/补充引导或预测卡）
- **THEN** UI MUST NOT 提供清空预约操作；用户仅可确认时间或按现有关闭逻辑退出

### Requirement: Post-write prompt MUST use dedicated next-appointment sheet when empty or overdue

After a successful normal add or 「补充上一次」 for an appointment root, the client MUST NOT alter the existing add UI. When the root nextAt is missing/`0` or overdue, the client MUST present the dedicated next-appointment sheet; when nextAt is in the future, the client MUST NOT present that sheet. 预约事件正常新增/补充 **不得** 改原有新增页；成功后仅当空或过期 **必须** 弹专用 sheet；已是未来时间则 **不得** 弹。

#### Scenario: Add succeeds with empty nextAt

- **WHEN** 用户按现网流程新增预约事件记录成功且该根 `nextAt=0`
- **THEN** 客户端 MUST 弹出专用下一次预约 sheet，MUST NOT 为嵌入 nextAt 而修改原新增页

#### Scenario: Add succeeds with future nextAt

- **WHEN** 用户新增成功且该根已有未来 `nextAt`
- **THEN** 客户端 MUST NOT 弹出专用下一次预约 sheet

#### Scenario: Supplement succeeds when overdue

- **WHEN** 「补充上一次」成功且该根 `nextAt` 已过期
- **THEN** 客户端 MUST 弹出专用下一次预约 sheet

### Requirement: Dedicated next-appointment sheet MUST use logo title and datetime wheels

The dedicated sheet MUST use a top-bottom layout: top copy `{event logo}下一次{event name}预约时间`; bottom year/month/day/hour/minute scroll pickers. Confirm MUST PUT a positive nextAt and trigger pending sync. 专用 sheet **必须** 上语文案含 logo 与事件名，下为年月日时分滚轮；确认 **必须** PUT 正 nextAt 并触发 pending 同步。

#### Scenario: Confirm writes nextAt

- **WHEN** 用户在专用 sheet 确认所选日期时间
- **THEN** 客户端 MUST 对根 eventId PUT 对应正 nextAt，并 MUST 触发 pending 整表同步使该事件以该时间出现在 events 中
