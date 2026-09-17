## ADDED Requirements

### Requirement: Care-alert generate path SHALL expose SSE thinking then final items

The system SHALL provide a streamed care-alert generate path (device API via Go proxying Python) that emits thinking deltas compatible with the shared `\r` stage-clear rules and a terminal payload containing the daily `items` plus `usedToday`/`dailyLimit` (or equivalent). The client MUST use this path for manual「AI智能分析」when implementing streaming UX. Day-limit, single-flight, and cache write semantics MUST remain consistent with the existing blocking daily generate. 系统 **必须** 提供 care-alert 生成 SSE：思考增量 + 终态 items/用量；手动分析走此路径；日限/单飞/缓存语义与现网一致。

#### Scenario: 思考后出列表

- **WHEN** 已开通用户触发强制日分析且未触日限
- **THEN** 流 MUST 先推送至少一条 thinking（编排或 LLM）
- **AND** 结束前 MUST 推送含 items 的终态事件（可空列表）
- **AND** Go MUST 按既有规则写入/更新日缓存

#### Scenario: 日限仍业务错误

- **WHEN** 用户已达 care-alert 日限仍请求强制生成
- **THEN** 系统 MUST 以既有业务错误（或 SSE error 事件）拒绝
- **AND** MUST NOT 伪造 items

#### Scenario: 拉取缓存可不走思考流

- **WHEN** 客户端仅拉取当日已缓存结果且不 force 生成
- **THEN** MAY 继续使用非流式 daily GET
- **AND** MUST NOT 无故消耗日额度
