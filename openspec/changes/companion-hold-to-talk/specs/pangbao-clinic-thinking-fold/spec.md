## ADDED Requirements

### Requirement: Thinking UI MUST NOT render when assistant answer is non-empty

When a companion/clinic assistant item has a non-empty `answer`, the client MUST NOT render any thinking fold/expand UI for that item (including history restored from local cache or `session_sync`). The folded-tail and expand requirements in this capability apply only while the item has no non-empty answer (e.g. in-flight thinking-only streaming).

当助手项已有非空 `answer` 时，客户端 **必须** 不渲染任何 thinking 折叠/展开 UI（含历史）。本能力中的折叠尾部与展开条款 **仅** 适用于尚无非空 answer 的展示（如仅 thinking 流式中）。

#### Scenario: 有 answer 不展示折叠思考块

- **WHEN** 助手项 answer 非空
- **THEN** UI MUST NOT 展示折叠或展开态 thinking 块

#### Scenario: 无 answer 时流式 thinking 仍可折叠展示

- **WHEN** 进行中轮次 thinking 非空且 answer 仍为空
- **THEN** 客户端 MAY 按折叠尾部规则展示 thinking

## MODIFIED Requirements

### Requirement: Folded thinking block SHALL show tail window of latest content

When the thinking block is shown (assistant `answer` is empty) and collapsed (`thinkingExpanded == false`), the client MUST render the thinking text inside a fixed-height window that displays the **tail** (most recently appended portion) of the content. The client MUST NOT rely on inner `ScrollController.jumpTo` to follow `thinking_delta` streaming updates in folded mode. When `answer` becomes non-empty, the thinking block MUST NOT be shown (see ADDED requirement above).

当思考块处于展示条件（answer 为空）且折叠态时，客户端 MUST 在固定高度窗口内渲染 thinking 文本的**尾部**。一旦 answer 非空，MUST NOT 再展示 thinking 块。

#### Scenario: 流式 thinking 折叠态可见最新尾部

- **WHEN** 助手 thinking 通过 `thinking_delta` 持续增长、answer 仍为空、且思考块处于折叠态
- **THEN** 折叠窗口 MUST 展示 thinking 字符串末尾可见区域（含流式光标 `▍` 若启用）
- **AND** 用户 MUST NOT 需要手动内层滚动才能看到最新追加内容

#### Scenario: 单段长文无换行仍跟随尾部

- **WHEN** thinking 为少换行长段落、answer 仍为空、且视觉高度超过折叠窗口
- **THEN** 折叠窗口 MUST 仍展示段落尾部而非开头
