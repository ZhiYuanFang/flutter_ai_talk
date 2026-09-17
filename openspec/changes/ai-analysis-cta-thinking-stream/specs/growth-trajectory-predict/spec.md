## ADDED Requirements

### Requirement: Growth trajectory thinking stream SHALL include LLM reasoning deltas

In addition to LangGraph node orchestration captions emitted via `with_node_thinking` (or equivalent), the growth-trajectory Python graph SHALL stream LLM reasoning/thinking content to the existing SSE `thinking` channel when the model exposes it (`llm_client.stream` with thinking enabled, or equivalent). Orchestration-stage clears MUST continue to use `\r` only at stage boundaries; per-token LLM thinking MUST NOT prepend `\r` on every chunk. Go and Flutter MUST continue to pass through `thinking` events unchanged. 成长轨迹 **必须** 在编排 caption 之外透出 LLM 思考增量（模型支持时）；token 级 **不得** 每片 `\r`；Go/Flutter 透传不变。

#### Scenario: 节点间可见 LLM 思考

- **WHEN** 用户开始轨迹预测且模型返回 reasoning/thinking 增量
- **THEN** 客户端思考区 MUST 逐步展示这些增量（可与编排文案衔接）
- **AND** MUST NOT 仅在整段 `invoke` 结束后才突然出现长文

#### Scenario: 无 reasoning 时仍有编排 caption

- **WHEN** 模型不提供 reasoning_content
- **THEN** 客户端 MUST 仍至少展示节点编排阶段文案
- **AND** MUST NOT 因缺少 LLM thinking 而失败整轮

### Requirement: Growth primary CTA SHALL sit below body content

The growth-trajectory workspace SHALL place「轨迹预测」/「重新预测」and `今日已用 x/y 次` below the main body, not in the AppBar. 成长主 CTA 与用量 **必须** 在正文下。

#### Scenario: AppBar 无预测按钮

- **WHEN** 用户查看已开通成长工作台
- **THEN** AppBar actions MUST NOT 包含轨迹预测/重新预测
