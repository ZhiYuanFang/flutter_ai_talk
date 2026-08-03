## REMOVED Requirements

### Requirement: 按钮路径强乐观插入

**Reason**: 产品改为 HTTP 成功后再入列（飞入归 WS），取消 `pending:*` 乐观插入。  
**Migration**: 见本文件 ADDED「按钮路径同步成功后入列」；飞入见 `home-event-record-fly`。

### Requirement: 并行 add 与响应 id 替换

**Reason**: 不再先插 pending 再 replace。  
**Migration**: 成功响应直接以服务端 id 插入一行。

### Requirement: time 型 pending 期间停止计时

**Reason**: 按钮路径不再产生 pending 行。  
**Migration**: 仅对已有服务端 id 的进行中计时按既有 stop 规则处理；若磁盘残留 `pending:*`，实现期只读或过滤。

## ADDED Requirements

### Requirement: Button-path add MUST wait for HTTP success before list insert

On bottom-button event add (`time` / `one` / `number` and catalog leaf), the client MUST call `POST /device/history/api/event/add` before inserting a history row, and MUST insert at most one row using the server `data.id` only after success. The client MUST NOT insert a `pending:*` row for this path. 底部按钮添加路径 **必须** 先发起 add HTTP，**仅在成功**后以服务端 `data.id` 插入至多一行；**不得**再为该路径插入 `pending:*` 行。

#### Scenario: add 成功后入列

- **WHEN** 用户完成合法按钮添加且 add 返回 `code == 0` 且 `data.id` 有效
- **THEN** 列表 MUST 出现以该服务端 id 标识的新行
- **AND** MUST NOT 曾出现对应的 `pending:*` 行

#### Scenario: add 失败不入列

- **WHEN** add 业务失败或传输失败
- **THEN** 列表 MUST NOT 新增该次添加对应行
- **AND** 客户端 MUST Toast 错误（与现网失败提示一致或等价）

### Requirement: Button-path add in-flight MUST disable further adds

While a button-path add HTTP request is in flight, the client MUST disable home UI controls that would start another `_submitEventAdd` (or equivalent) for event grid / number confirm paths. 按钮路径 add 请求进行中时，客户端 **必须** 禁用会再次发起添加的入口控件。

#### Scenario: 请求中连点

- **WHEN** 一次 add HTTP 尚未完成
- **AND** 用户再次点击事件按钮
- **THEN** 客户端 MUST NOT 发起第二次并发 add（入口禁用或忽略）

### Requirement: No history outbox for add or update

The client MUST NOT enqueue history ADD or UPDATE operations into a local outbox file or flusher for deferred sync; failed HTTP mutations MUST surface to the user without silent offline queueing. 客户端 **不得** 再将历史 ADD/UPDATE 写入本地 outbox 或经 flusher 延迟同步；HTTP 失败 **必须** 对用户可见，**不得**静默入队。

#### Scenario: 删除 outbox 后添加失败

- **WHEN** add HTTP 因网络失败
- **THEN** 客户端 MUST Toast 失败
- **AND** MUST NOT 写入 ADD outbox 或 pending 行等待 flush

## MODIFIED Requirements

### Requirement: WebSocket 同 id 合并无重复

When WebSocket or SSE delivers create/update for a record id already present locally (including after button-path success insert), the client MUST merge fields via upsert and MUST NOT insert a duplicate row. Fly animation for that id MUST follow `home-event-record-fly` (at most one WS-owned fly when awaiting or truly new). 当 WS/SSE 推送的 `record.id` 在本地已存在（含按钮路径成功插入的服务端 id）时，**必须** upsert 合并字段，**不得**重复插行；飞入 **必须** 遵循 `home-event-record-fly`（awaiting 或真正新增时至多一次 WS 飞入）。

#### Scenario: WS 在本机成功插入之后到达

- **WHEN** 按钮路径已成功插入 serverId 并登记 awaiting，随后 WS 推送同 id 的 create/update
- **THEN** 系统必须更新该行字段，列表行数不变
- **AND** MUST 播放至多一次飞入（见 `home-event-record-fly`）
- **AND** 后续同 id 的普通 update MUST NOT 再飞

### Requirement: 语音与文字不得乐观插入

The voice and text input paths MUST NOT perform optimistic history insertion; they SHALL continue to rely on WebSocket-only list updates. **语音**与**文字**输入路径（`sendCommand` 等）**不得**做乐观插行，**必须**仍仅依赖 WebSocket 更新列表。

#### Scenario: 语音落库

- **WHEN** 用户通过语音发送指令且服务端落库
- **THEN** 列表仅在 WS 推送新 id 时插入，且飞行动画按 WS 新增规则触发

### Requirement: add 请求体与既有映射一致

Add HTTP bodies MUST be built via the same mapping as `home-button-input-mode` (`buildEventAddBody`, no `eventUnit`). add 请求体 **必须** 共用既有 `buildEventAddBody` 映射，且 **不得** 包含 `eventUnit`。

#### Scenario: time 重复校验仍生效

- **WHEN** 同 `eventId` 已有进行中计时（服务端 id 行）
- **THEN** 系统必须拒绝再次开始并 Toast「{eventName}已在计时中」
