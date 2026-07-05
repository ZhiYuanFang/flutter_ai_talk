## ADDED Requirements

### Requirement: 历史 outbox flush MUST 遵守副作用 HTTP 治理

Background flush triggered by `historyWsReadyStream` MUST use a single in-flight Future shared by all concurrent ready events, MUST NOT loop-retry within the same WS ready session on transport failure, and MUST NOT be started from Riverpod provider `build` without an idempotent lazy starter. 由 WS ready 触发的 outbox flush MUST single-flight 去重；同一 ready 周期内传输失败 MUST 结束本次 flush、不得 tight loop；不得在 provider 构造中无防护地 `unawaited` 启动 flush。

#### Scenario: flush single-flight

- **WHEN** `isHistoryWebSocketReady` 上升沿在 200ms 内触发两次或 flush 进行中再次 ready
- **THEN** 客户端 MUST 仅运行一个 in-flight flush Future
- **AND** 后续触发 MUST await 同一 Future 或 no-op

#### Scenario: 传输失败不 tight loop

- **WHEN** flush 中某条 ADD 因网络失败
- **THEN** 客户端 MUST 停止当前 flush 批次内后续重试该条
- **AND** MUST 保留 outbox 直至下一次 WS ready 上升沿

#### Scenario: provider 构造不得裸发 flush

- **WHEN** `feedRepositoryProvider` 首次创建
- **THEN** MUST NOT 在无 session/device 守卫的情况下自动 POST add/update
- **AND** flusher 启动 MUST 绑定 `watchLatest` 订阅或等价的显式 home 激活路径
