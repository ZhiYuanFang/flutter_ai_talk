## MODIFIED Requirements

### Requirement: 并行 add 与响应 id 替换

The client MUST enqueue or immediately call `POST /device/history/api/event/add` after optimistic insert: when `isHistoryWebSocketReady` is true it MUST POST in parallel with UI feedback; when false it MUST defer POST until the next history WebSocket ready flush. On success it MUST parse `data.id` and replace `pending:<uuid>` in place. 乐观插入后：WS 已就绪时 MUST 并行发起 add；WS 未就绪时 MUST 延迟至 outbox flush（见 `history-outbox-flush`）。成功时 MUST 从响应解析 `data.id` 并原地替换 pending id，不得再插入第二行。

#### Scenario: add 成功

- **WHEN** add 返回 `code == 0` 且 `data.id` 有效（即时 POST 或 flush）
- **THEN** 列表中该条记录 id 变为服务端 id，顺序与字段保持不变，且不得触发第二次飞行动画

#### Scenario: add 业务失败

- **WHEN** add 返回 `code != 0` 或抛出 `ApiBusinessException`
- **THEN** 系统必须移除 pending 记录并 Toast `message`，且不得保留乐观行

#### Scenario: add 网络或解析失败

- **WHEN** add 请求因网络/超时/非业务异常失败，或 `data.id` 缺失/无效
- **THEN** 系统 MUST 保留 pending 记录
- **AND** MUST NOT Toast
- **AND** MUST 在下一次历史 WebSocket ready 时重试 flush

### Requirement: time 型 pending 期间停止计时

The UI MUST allow stopping an active timing record whose id is still `pending:*` when the stop action only updates local state and merged ADD flush semantics apply; it MUST disable stop only while a stop request is in-flight for that row. 对 `pending:*` 进行中计时，用户 MUST 可以停止（本地写入 `endTime`）；flush 前 MUST NOT 调用带服务端 id 的 `updateHistoryRecord`；停止进行中 MUST 禁用重复点击。

#### Scenario: WS 未就绪 pending 停止

- **WHEN** 乐观 time 行仍为 pending、用户点击停止、且 `isHistoryWebSocketReady == false`
- **THEN** 系统 MUST 本地更新 `endTime` 并保留 pending 行
- **AND** MUST NOT 调用 `POST .../event/update` with pending id
- **AND** flush ADD 时 MUST 发送含结束时间的 add body

#### Scenario: replace 完成后停止

- **WHEN** pending 已替换为服务端 id
- **THEN** 停止计时行为与现网 active-timing-stop 一致（即时 POST 或 UPDATE outbox，依 WS 就绪状态）

## REMOVED Requirements

无。
