## ADDED Requirements

### Requirement: Care-alert daily response usage fields SHALL drive feeding workspace copy

When the client receives care-alert daily payload fields `usedToday` and `dailyLimit`, it SHALL persist them in analysis UI state and MUST surface them under the feeding workspace CTA as `今日已用 {usedToday}/{dailyLimit} 次`. 客户端 **必须** 解析并展示 daily 返回的已用/上限字段。

#### Scenario: force 生成后刷新已用

- **WHEN** 用户完成一次强制日分析且响应含更新后的 `usedToday`/`dailyLimit`
- **THEN** 喂养工作台用量文案 MUST 更新为最新已用/上限

### Requirement: Feeding manual analyze MAY stream thinking before list update

When the user taps「AI智能分析」and a generate/force path runs, the client SHOULD consume a streamed thinking channel (see `care-alert-thinking-stream`) and MUST NOT rely solely on a static「正在思考中」label once streaming is available. Until the stream completes successfully, the daily list MUST NOT be replaced with a partial invent. 手动分析在具备流式能力后 **必须** 展示思考流；成功完成前 **不得** 用半成品列表冒充结果。

#### Scenario: 分析中展示思考区

- **WHEN** 用户点击「AI智能分析」且思考 SSE（或等价）已连通
- **THEN** 客户端 MUST 展示可更新的思考内容区（支持 `\r` 阶段清理规则）
- **AND** 流正常结束后 MUST 用最终 items 刷新列表
