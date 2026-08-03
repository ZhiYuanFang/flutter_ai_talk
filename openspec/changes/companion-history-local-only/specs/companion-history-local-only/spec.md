## ADDED Requirements

### Requirement: Companion history UI MUST NOT apply session_sync turns

When the clinic WebSocket delivers a `session_sync` frame, the companion chat UI MUST NOT rebuild, clear, or reorder in-memory message items from the frame's `turns` array. The client MAY log the frame for diagnostics. 当 Clinic WS 下发 `session_sync` 时，陪伴聊天 UI **不得** 根据帧内 `turns` 重建、清空或重排内存消息列表；客户端 MAY 记录诊断日志。

#### Scenario: 非空 session_sync 不改列表

- **WHEN** 陪伴页已有本地/内存消息
- **AND** 收到非空 `session_sync.turns`
- **THEN** `_items`（或等价消息列表）MUST 保持不变（相对该帧处理前）
- **AND** MUST NOT 插入因该 sync 产生的截断 divider

#### Scenario: 空 session_sync 不改列表

- **WHEN** 收到 `session_sync` 且 `turns` 为空
- **THEN** 客户端 MUST NOT 因该帧清空或改写消息列表

### Requirement: Companion history display MUST be local-frontend only

The companion history list MUST be populated only from local session store hydration, in-session user sends, live clinic stream frames (deltas/done/error/cancel), tip injection, and explicit clear-history actions. 陪伴历史列表 **必须** 仅由本地会话 hydrate、本会话用户发送、实时 clinic 流式帧、tip 注入与显式清理填充。

#### Scenario: 冷启动只 hydrate 本地

- **WHEN** 用户打开陪伴且内存列表为空
- **AND** 本地 store 有 completed/tip 条目
- **THEN** 客户端 MUST 从本地 store 恢复展示
- **AND** MUST NOT 等待或依赖 `session_sync` 才展示这些条目

#### Scenario: 实时问答仍可用

- **WHEN** 用户发送问题且 WS 返回 `answer_delta` / `answer_done`
- **THEN** 列表 MUST 仍按既有流式规则更新该轮助手气泡
