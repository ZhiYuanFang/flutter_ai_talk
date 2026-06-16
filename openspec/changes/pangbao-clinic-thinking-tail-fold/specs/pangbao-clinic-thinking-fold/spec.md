## ADDED Requirements

### Requirement: Folded thinking block SHALL show tail window of latest content

When the clinic thinking block is collapsed (`thinkingExpanded == false`), the client MUST render the thinking text inside a fixed-height window that displays the **tail** (most recently appended portion) of the content. The client MUST NOT rely on inner `ScrollController.jumpTo` to follow `thinking_delta` streaming updates in folded mode.

当胖宝诊疗思考块处于折叠态（`thinkingExpanded == false`）时，客户端 MUST 在固定高度窗口内渲染 thinking 文本的**尾部**（最近追加片段）。折叠态 MUST NOT 依赖内层 `ScrollController.jumpTo` 来跟随 `thinking_delta` 流式更新。

#### Scenario: 流式 thinking 折叠态可见最新尾部

- **WHEN** 助手 thinking 通过 `thinking_delta` 持续增长且思考块处于折叠态
- **THEN** 折叠窗口 MUST 展示 thinking 字符串末尾可见区域（含流式光标 `▍` 若启用）
- **AND** 用户 MUST NOT 需要手动内层滚动才能看到最新追加内容

#### Scenario: 单段长文无换行仍跟随尾部

- **WHEN** thinking 为少换行长段落且视觉高度超过折叠窗口
- **THEN** 折叠窗口 MUST 仍展示段落尾部而非开头
- **AND** MUST NOT 因 `\n` 计数不足而仅显示段落开头

### Requirement: Expanded thinking block SHALL show full thinking scrollable text

When the user expands the thinking block (`thinkingExpanded == true`), the client MUST display the full thinking string and MUST allow vertical scrolling when content exceeds the available area.

当用户展开思考块（`thinkingExpanded == true`）时，客户端 MUST 展示完整 thinking 字符串；内容超出可用区域时 MUST 允许纵向滚动查看。

#### Scenario: 点击展开查看全文

- **WHEN** 用户点击折叠态思考块的「点击展开」或等效区域
- **THEN** `thinkingExpanded` MUST 变为 true
- **AND** 用户 MUST 可看到完整 thinking 文本而不仅是尾部窗口

#### Scenario: 再次点击可折叠回尾部窗口

- **WHEN** 用户在展开态再次点击思考块切换折叠
- **THEN** 思考块 MUST 恢复折叠尾部窗口展示

### Requirement: Folded overflow hint SHALL use visual overflow not newline count

The client MUST show the folded overflow affordance（例如「点击展开」与可选顶部渐变）when the laid-out thinking text height exceeds the folded window height. The client MUST NOT use newline (`\n`) count alone as the sole overflow condition.

客户端 MUST 在 thinking 文本排版高度超过折叠窗口高度时显示折叠溢出提示（如「点击展开」与可选顶部渐变）。MUST NOT 仅以换行符（`\n`）数量作为唯一溢出判定条件。

#### Scenario: 长段落触发点击展开提示

- **WHEN** thinking 无多余 `\n` 但排版高度超过折叠窗口
- **THEN** 用户 MUST 看到「点击展开」或等效溢出提示

#### Scenario: 短 thinking 不显示溢出提示

- **WHEN** thinking 排版高度不超过折叠窗口
- **THEN** 客户端 MUST NOT 显示「点击展开」溢出提示

### Requirement: Folded thinking MUST NOT expose follow-latest pin UI

In folded mode, the client MUST NOT display the「跟随最新」control and MUST NOT maintain `thinkingInnerPinned` pin state for inner scroll following. Tail-window rendering replaces inner auto-scroll follow in folded mode.

折叠态下，客户端 MUST NOT 展示「跟随最新」控件，且 MUST NOT 为内层滚动跟随维护 `thinkingInnerPinned` pin 状态；尾部窗口取代折叠态内层自动滚动跟随。

#### Scenario: 折叠流式过程无跟随最新 chip

- **WHEN** thinking 流式更新且思考块处于折叠态
- **THEN** 思考块标题行 MUST NOT 显示「跟随最新」按钮或 chip
