## MODIFIED Requirements

### Requirement: Trajectory session SHALL use Go SSE with thinking, question, and result phases

The client SHALL call only Go APIs (not Python). Starting or answering a turn MUST consume an SSE (or equivalent streamed) session that can emit thinking deltas, a question payload, a result payload, and errors. While thinking is streaming, the module MUST show an adaptive-height thinking area and MUST apply the shared `\r` stage-clear rules via `applyThinkingStageDelta` (or equivalent). When a question or result event arrives, the client MUST hide the thinking area. When a question presents visible free-text input (`format=free_text`, or choice after manual text entry), voice fill into that field MUST follow `growth-trajectory-voice-input`. 客户端 **必须** 只请求 Go；回合 **必须** 消费含 thinking / question / result / error 的流；思考中 **必须** 自适应高度展示并以 `\r` 规则更新；收到 question 或 result 后 **必须** 隐藏思考区；出现可见文本输入时语音填框见 `growth-trajectory-voice-input`。

#### Scenario: 点击轨迹预测进入流式思考

- **WHEN** 已开通用户点击「轨迹预测」或「重新预测」且日限未拒
- **THEN** 客户端 MUST 隐藏该主按钮并开始 turn 流
- **AND** MUST 实时展示 thinking（支持 `\r` 清阶段）
- **AND** 思考区高度 MUST 随内容自适应（可设上限并内部滚动）

#### Scenario: 收到提问

- **WHEN** 流返回 `question`
- **THEN** 客户端 MUST 隐藏思考区
- **AND** MUST 在当前卡片内展示题干
- **AND** 当 `format` 为 choice 时 MUST 渲染恰好两个选项按钮（文案为服务端 `choices`，不写死「是/否」）
- **AND** 当 `format` 为 free_text 时 MUST 提供输入与提交
- **AND** 当文本输入可见时 MUST 提供按住说话填框（见 `growth-trajectory-voice-input`）

#### Scenario: 收到结果

- **WHEN** 流返回 `result` Markdown
- **THEN** 客户端 MUST 隐藏思考区
- **AND** MUST 以富文本/Markdown 展示结果
- **AND** MUST 显示「重新预测」

#### Scenario: 日限错误 Toast

- **WHEN** Go 返回日限或业务错误 message
- **THEN** 客户端 MUST Toast 该 message（或非空服务端文案）
- **AND** MUST NOT 在本地自行累计或拦截「第 N 次」日限
- **AND** 问答中途 submit 失败以外的成功提问 MUST NOT 被客户端计为一次日限消耗
