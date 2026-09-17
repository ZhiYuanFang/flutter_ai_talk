## ADDED Requirements

### Requirement: Streaming and expanded clinic thinking body SHALL use AiThinkingPane

While the clinic assistant thinking block is shown with empty `answer`, the **streaming** thinking body and the **expanded** (`thinkingExpanded == true`) full thinking body MUST be rendered with the shared `AiThinkingPane` (same follow-bottom / pause-on-scroll-up / jump-button semantics as other AI analysis surfaces). The **folded** thinking tail window MUST remain governed by the existing folded-tail requirements and MUST NOT use `ScrollController.jumpTo` to follow `thinking_delta` in folded mode.

诊疗助手在 `answer` 为空且展示 thinking 时：流式正文与展开态全文 **必须** 使用共享 `AiThinkingPane`；折叠尾部窗口仍遵守既有折叠尾部需求，折叠态 **不得** 用 `jumpTo` 跟 `thinking_delta`。

#### Scenario: 流式思考用共享 pane 跟底

- **WHEN** 诊疗对话 thinking 经 `thinking_delta` 增长、answer 仍为空、且思考块处于流式展示（非折叠尾部窗口）
- **THEN** 思考正文 MUST 由 `AiThinkingPane` 渲染并默认跟滚最新内容

#### Scenario: 展开态用共享 pane

- **WHEN** 用户展开思考块且 answer 仍为空
- **THEN** 完整 thinking 正文 MUST 由 `AiThinkingPane` 提供可滚动查看与跟滚/暂停/回底语义

#### Scenario: 折叠尾部不改用 jumpTo 跟流

- **WHEN** 思考块处于折叠态且 thinking 仍在增长
- **THEN** 客户端 MUST 继续以固定高度尾部窗口展示最新尾部
- **AND** MUST NOT 依赖内层 `ScrollController.jumpTo` 作为折叠态跟流手段
