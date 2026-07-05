## ADDED Requirements

### Requirement: 历史 Outbox MUST 在 WS 就绪时静默 flush

The client MUST defer `POST /device/history/api/event/add` for button-path optimistic rows while `isHistoryWebSocketReady` is false, MUST flush queued operations on each rising edge of `isHistoryWebSocketReady` (including after manual reconnect from gave-up), and MUST NOT show success toasts for background flush completion. 当历史 WebSocket 未就绪时，客户端 MUST 将按钮路径的 ADD/UPDATE 保留在本地 outbox；每次 `isHistoryWebSocketReady` 由 false 变为 true 时 MUST single-flight 按序 flush；flush 成功 MUST 静默（不得 Toast「已同步」类提示）。

#### Scenario: WS 未就绪时按钮 add

- **WHEN** 用户点击底部喂养按钮且已登录、已绑定宝宝，但 `isHistoryWebSocketReady == false`
- **THEN** 系统 MUST 立即插入 `pending:<uuid>` 乐观行并播放飞行动画
- **AND** MUST NOT 调用 `_ensureHistoryWsForSend` 拦截
- **AND** MUST NOT 因 add 未发出而移除 pending 行

#### Scenario: WS ready 触发 flush ADD

- **WHEN** `isHistoryWebSocketReady` 从 false 变为 true 且存在至少一条 `pending:*` 行
- **THEN** 客户端 MUST 按列表顺序对每条 pending 从当前 `rawPayload` 构造 add body 并调用 `POST /device/history/api/event/add`
- **AND** 成功时 MUST `replaceRecordId(pending, serverId)` 且不得第二次飞行动画

#### Scenario: gaveUp 下不 flush

- **WHEN** 历史 WS phase 为 `gaveUp` 且用户本地 add 产生 pending 行
- **THEN** 客户端 MUST NOT flush
- **AND** 用户点击横幅重连且 WS ready 后 MUST flush 积压 outbox

#### Scenario: flush 成功静默

- **WHEN** 后台 flush 完成且用户未主动触发该次 POST
- **THEN** 系统 MUST NOT 展示成功 Toast

### Requirement: UPDATE outbox MUST 覆盖 time 型 stop/update

The client MUST enqueue `POST /device/history/api/event/update` operations for time-type stop (and equivalent update) on records with non-pending server ids when `isHistoryWebSocketReady` is false, apply optimistic local `endTime` immediately, and flush updates after pending ADDs in the same flush pass. 对已有服务端 id 的进行中计时，WS 未就绪时用户停止 MUST 本地写入 `endTime` 并将 update body 写入 UPDATE outbox；flush 时 MUST 在所有 pending ADD 之后按 FIFO 发送 update。

#### Scenario: server id 停止且 WS 未就绪

- **WHEN** 用户对非 pending 的进行中计时点击停止且 `isHistoryWebSocketReady == false`
- **THEN** UI MUST 立即展示已结束（本地 `endTime`）
- **AND** 系统 MUST 将 update 写入 `HistoryOutboxStore` 而非立即 POST

#### Scenario: pending 停止合并为 ADD

- **WHEN** 用户对 `pending:*` 进行中计时点击停止且 add 尚未 flush
- **THEN** 系统 MUST 仅更新 pending 行 `rawPayload.endTime`
- **AND** MUST NOT 写入 UPDATE outbox
- **AND** flush 时 MUST 以含 `endTime` 的 body 发送单次 ADD

#### Scenario: UPDATE flush 顺序在 ADD 之后

- **WHEN** 同一 flush 周期内既有 pending ADD 又有 UPDATE 队列项
- **THEN** 客户端 MUST 先完成全部 pending ADD，再 FIFO flush UPDATE

### Requirement: flush 失败 MUST 按类型分流

Transport or network failures during flush MUST retain the outbox entry and MUST NOT toast; business failures (`ApiBusinessException`, including quota/login codes) MUST toast and MUST apply type-specific rollback. flush 传输/网络失败 MUST 保留队列并静默；业务失败 MUST Toast 用户可读 `message`，且 ADD 失败 MUST 移除 pending 行，UPDATE 失败 MUST 回滚本地 optimistic 结束态并保持进行中。

#### Scenario: ADD 网络失败

- **WHEN** flush 时 `POST .../event/add` 因网络/超时/非业务异常失败
- **THEN** pending 行 MUST 保留
- **AND** 系统 MUST NOT Toast
- **AND** 下一次 WS ready 上升沿 MUST 重试

#### Scenario: ADD 业务失败

- **WHEN** flush add 返回 `ApiBusinessException`
- **THEN** 系统 MUST Toast `message`
- **AND** MUST 移除对应 pending 行并取消未完成飞行动画

#### Scenario: UPDATE 网络失败

- **WHEN** flush update 网络失败
- **THEN** UPDATE 队列项 MUST 保留
- **AND** 本地 optimistic `endTime` MUST 保留
- **AND** MUST NOT Toast

#### Scenario: UPDATE 业务失败

- **WHEN** flush update 返回 `ApiBusinessException`
- **THEN** 系统 MUST Toast `message`
- **AND** MUST 回滚该记录为进行中计时（清除本地结束 `endTime`）
- **AND** MUST 从 UPDATE outbox 移除该项

### Requirement: Outbox MUST 在登出与换宝宝时隔离

The client MUST clear in-memory pending rows and the on-disk UPDATE outbox for the current session on sign-out, and MUST only flush operations for the active `deviceNo`. 登出时 MUST 清除当前用户 pending 与 UPDATE outbox 文件；flush MUST 仅处理 `_deviceNoGetter()` 当前非空 deviceNo，不得将旧 device 队列发到新 device。

#### Scenario: 登出清队列

- **WHEN** 用户登出且 session `isLoggedIn` 变为 false
- **THEN** 客户端 MUST 丢弃未 flush 的 UPDATE outbox
- **AND** MUST 清除 home history state 中的 `pending:*` 行（与现网登出清历史一致）

#### Scenario: 切换宝宝

- **WHEN** 本地 `deviceNo` 从 A 变为 B
- **THEN** flush MUST 仅发送 B 的 pending/outbox
- **AND** A 的 outbox 文件 MUST 保留在磁盘但 MUST NOT 自动上传至 B

### Requirement: WS ready 时按钮路径 MAY 立即 add

When `isHistoryWebSocketReady` is already true at tap time, the client MAY POST add immediately without waiting for the flusher, while still using optimistic insert and id replacement semantics. 若用户点击按钮时 WS 已就绪，客户端 MAY 在乐观插入后立即 POST add（与 flusher 并行不冲突），成功规则与 id 替换不变。

#### Scenario: WS 已就绪即时 add

- **WHEN** 用户点击按钮且 `isHistoryWebSocketReady == true`
- **THEN** 系统 MUST 乐观插入后立即发起 add HTTP
- **AND** 成功时 MUST replace pending id，不得依赖 flush 作为唯一 upload 路径

### Requirement: refreshFromRemote MUST 保留未 flush 的 pending 行

The client MUST NOT remove local `pending:*` rows when `refreshFromRemote` replaces the home history list from HTTP page 1; merged snapshots persisted to disk MUST retain pending rows until flush succeeds or business failure removes them. `refreshFromRemote` 用 HTTP 第一页刷新首页历史时，**不得**移除尚未 flush 的 `pending:*` 行；落盘 snapshot MUST 含这些 pending，直至 flush 成功或业务失败移除。

#### Scenario: bootstrap refresh 期间已 add pending

- **WHEN** 用户于 `refreshFromRemote` in-flight 或完成窗口内插入 `pending:*`，且远端 list 尚未含对应记录
- **THEN** 客户端 MUST 将 pending 行合并进 refresh 后的 `items` 并持久化
- **AND** MUST NOT 静默删除 pending
- **AND** MUST NOT Toast

#### Scenario: refresh 完成后 WS 已就绪

- **WHEN** `refreshFromRemote` 完成且合并后仍存在 `pending:*`，且 `isHistoryWebSocketReady == true`
- **THEN** 客户端 MUST 触发 `flushPendingHistoryOutbox`（single-flight）
