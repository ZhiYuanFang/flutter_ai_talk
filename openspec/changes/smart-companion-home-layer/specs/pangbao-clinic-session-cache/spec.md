## MODIFIED Requirements

### Requirement: session_sync merge preserves local thinking

When `session_sync` delivers non-empty `turns`, the client MUST treat server data as authoritative for matching `question`/`answer` pairs, MUST preserve locally known `thinking` for matching turns when server data omits thinking, and MUST retain local completed turns whose questions are absent from the server payload above a plain horizontal divider (no caption text) placed before the server-authoritative block. 当 `session_sync` 含非空 `turns` 时，匹配轮次以服务端 Q/A 为权威并保留本地 thinking；服务端未包含的本地 completed 轮次 **必须** 保留在上方，并以**纯线无字**横线与下方服务端块分隔。

#### Scenario: Merge thinking from memory

- **WHEN** `session_sync` 返回的某轮 `question` 与 merge 前内存中某轮 question 一致（trim 后相等），且内存中该轮 assistant 有非空 `thinking`
- **THEN** merge 后该轮 assistant **必须**保留该 `thinking`
- **AND** `answer` **必须**采用服务端 `turn.answer`

#### Scenario: Merge thinking from local cache

- **WHEN** 内存无 thinking 但本地缓存中同 question 轮次含 `thinking`
- **THEN** merge 后**必须**从缓存恢复 `thinking`

#### Scenario: Local-only turns kept above plain divider

- **WHEN** 本地 completed 含 question 不在本次 `session_sync.turns` 中
- **THEN** merge 后这些轮次 MUST 仍展示于列表上方
- **AND** MUST 在其与服务端权威块之间插入无文字长横线

#### Scenario: Ignore session_sync during active streaming

- **WHEN** 存在进行中的流式轮次（`_activeAssistant != null`）
- **THEN** 客户端**必须**忽略 `session_sync` 帧（与现网一致，不得中断当前回答）

## ADDED Requirements

### Requirement: Local companion session MUST NOT auto-expire after 12 hours

The client MUST NOT delete or hide companion/clinic local session cache solely because 12 hours have elapsed. 客户端 **不得** 仅因超过 12 小时自动删除或隐藏本地陪伴/clinic 会话缓存。

#### Scenario: Over-12h local history still hydrates

- **WHEN** 本地 store 中记录写入已超过 12 小时且用户再次进入陪伴页
- **THEN** 客户端 MUST 仍可 hydrate 并展示这些记录（除非用户已确认清理）
