## ADDED Requirements

### Requirement: Range history fetch SHALL NOT succeed as empty when deviceNo is unavailable

When the client lacks a usable local `deviceNo` for authenticated history APIs, attempts to load the seven-day prediction range (filter / v2 list or equivalent wrappers) MUST NOT be treated as a successful empty result. The client MUST NOT mark the range store `ready` with an empty item list solely because `deviceNo` was missing. After login, ensure/load paths MUST attempt to refresh local `deviceNo` from persistence before calling the network; if `deviceNo` remains unavailable, the load MUST fail or defer without locking a successful empty ready state.

本地无可用 `deviceNo` 时，近 7 日 range 拉取 **不得** 被当成成功空列表，**不得** 仅因此将 store 标为 `ready` 且 items 为空。已登录 ensure **必须** 先尝试从本地持久化刷新 `deviceNo`；仍无则失败或推迟，**不得** 锁死假成功空态。

#### Scenario: deviceNo 空不标 ready

- **WHEN** 已登录但内存中 `deviceNo` 不可用且尚未从本地缓存刷新成功
- **AND** 触发 range ensure / filter 封装
- **THEN** 客户端 MUST NOT 将 range store 标记为成功 ready 且 items 为空
- **AND** MUST NOT 把「无 deviceNo」路径记为与「窗内确无记录」相同的成功空拉取

#### Scenario: ensure 前刷新 deviceNo

- **WHEN** 已登录用户触发 range ensure 且当前 `deviceNo` 为空
- **THEN** 客户端 MUST 先尝试 `deviceNo` 本地 refresh（或等价读缓存）
- **AND** 若 refresh 后已有 `deviceNo`，MUST 再发起 filter（或等价）网络拉取

### Requirement: Range ensure SHALL retry when ready-empty but deviceNo becomes available

If the range store is already marked ready with an empty item list, and a usable `deviceNo` is now available, a subsequent ensure (including when opening the smart prediction page) MUST force a refetch instead of skipping solely because ready is true. A refetch that returns a genuine empty window MAY remain ready-empty.

若 range 已 ready 且 items 为空、但此时已有可用 `deviceNo`，后续 ensure（含进入智能预测页）**必须** 强制重拉，**不得** 仅因 ready 跳过。窗内确无记录时允许仍为空。

#### Scenario: 进页自愈假空

- **WHEN** range store 为 ready、items 为空，且本地已有非空 `deviceNo`
- **AND** 用户打开智能预测页（或其它消费方 ensure）
- **THEN** 客户端 MUST 重新请求近 7 日 range（filter 或等价）
- **AND** MUST NOT 因先前 ready 标志而跳过该次拉取
