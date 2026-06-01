## ADDED Requirements

### Requirement: 按钮路径强乐观插入

The client MUST insert a local history row immediately on bottom-button event tap (before add HTTP completes), using id `pending:<uuid>`, and MUST show success-style feedback (toast and fly animation) without waiting for WebSocket. 底部按钮（`time`、`one`、`number` 及目录 picker 选中的叶子事件）在 tap 后**必须**立即向本地历史列表插入 `id = pending:<uuid>` 的记录，并**必须**在不等待 WebSocket 的情况下呈现「已记录」Toast 体感与事件飞行动画。

#### Scenario: time 开始计时

- **WHEN** 用户点击 `eventType=time` 且通过「已在计时中」校验
- **THEN** 系统必须立即插入 pending 行（`eventNumber=0`，`endTime=0`），Toast「已记录{eventName}」，并触发一次飞行动画

#### Scenario: one 一次性

- **WHEN** 用户点击 `eventType=one`
- **THEN** 系统必须立即插入 pending 行（`eventNumber=1`，起止为当前时刻），Toast 与飞行动画各一次

#### Scenario: number 二级页确认

- **WHEN** 用户在 number 二级页确认时间、数量与可选 remark
- **THEN** 系统必须按用户选择构造乐观行并立即插入，Toast 与飞行动画各一次

#### Scenario: 目录有子节点

- **WHEN** 用户经 catalog picker 选中叶子事件并走上述任一分支
- **THEN** 乐观插入规则与直接点击叶子一致

### Requirement: 并行 add 与响应 id 替换

The client MUST call `POST /device/history/api/event/add` in parallel after optimistic insert, and on success MUST parse `data.id` from the response envelope and replace `pending:<uuid>` with the server id in place. 乐观插入后**必须**并行发起 add；成功时**必须**从响应 envelope 解析 **`data.id`**，并在列表中将 pending id **原地替换**为服务端 id，**不得**再插入第二行。

#### Scenario: add 成功

- **WHEN** add 返回 `code == 0` 且 `data.id` 有效
- **THEN** 列表中该条记录 id 变为服务端 id，顺序与字段保持不变，且不得触发第二次飞行动画

#### Scenario: add 业务失败

- **WHEN** add 返回 `code != 0`
- **THEN** 系统必须移除 pending 记录并 Toast `message`，且不得保留乐观行

#### Scenario: add 网络或解析失败

- **WHEN** add 请求失败或 `data.id` 缺失/无效
- **THEN** 系统必须移除 pending 记录并 Toast 错误信息（与现网一致）

### Requirement: WebSocket 同 id 合并无重复

When WebSocket or SSE delivers create/update for a record id already present locally (including after pending-to-server replacement), the client MUST merge fields via upsert and MUST NOT insert a duplicate row or schedule a second fly animation. 当 WS/SSE 推送的 `record.id` 在本地已存在（含已由 pending 替换后的服务端 id）时，**必须** upsert 合并字段，**不得**重复插行，**不得**再次播放飞行动画。

#### Scenario: WS 在 replace 之后到达

- **WHEN** add 已成功 replace id，随后 WS 推送同 id 的 create/update
- **THEN** 系统必须更新该行字段，列表行数不变，且无第二次飞行动画

#### Scenario: WS 在 replace 之前到达且 id 为 pending

- **WHEN** WS 极少情况下携带与 pending 相同 id 的 payload
- **THEN** 系统必须合并到同一行，replace 后仍以服务端 id 为准

### Requirement: 语音与文字不得乐观插入

The voice and text input paths MUST NOT perform optimistic history insertion; they SHALL continue to rely on WebSocket-only list updates. **语音**与**文字**输入路径（`sendCommand` 等）**不得**做乐观插行，**必须**仍仅依赖 WebSocket 更新列表。

#### Scenario: 语音落库

- **WHEN** 用户通过语音发送指令且服务端落库
- **THEN** 列表仅在 WS 推送新 id 时插入，且飞行动画按 WS 新增规则触发

### Requirement: time 型 pending 期间停止计时

The UI MUST NOT allow stopping an active timing record whose id is still `pending:*` until add succeeds or the optimistic row is removed. 对 `id` 以 `pending:` 开头的进行中计时记录，在 add 完成 id 替换或失败移除之前，**不得**允许用户触发停止计时（update）；**必须**禁用或隐藏停止入口。

#### Scenario: add 进行中点击停止

- **WHEN** 乐观 time 行仍为 pending 且用户尝试停止
- **THEN** 系统不得调用 `updateHistoryRecord`，停止控件不可用

#### Scenario: replace 完成后停止

- **WHEN** pending 已替换为服务端 id
- **THEN** 停止计时行为与现网 `active-timing-stop` 一致

### Requirement: add 请求体与既有映射一致

Optimistic records and add HTTP bodies MUST be built via the same mapping as `home-button-input-mode` (`buildEventAddBody`, no `eventUnit`). 乐观记录与 add 请求体**必须**共用既有 `buildEventAddBody` 映射（含 `time`/`one`/`number` 规则），且**不得**包含 `eventUnit`。

#### Scenario: time 重复校验仍生效

- **WHEN** 同 `eventId` 已有进行中计时（含乐观 pending time 行）
- **THEN** 系统必须拒绝再次开始并 Toast「{eventName}已在计时中」
