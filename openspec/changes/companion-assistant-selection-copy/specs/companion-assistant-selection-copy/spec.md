## ADDED Requirements

### Requirement: Companion assistant selection persists after long-press

The companion chat UI SHALL allow a completed assistant answer bubble (including tip-injected assistant content) to establish a stable text selection after a long-press gesture ends, such that selection handles or an equivalent platform selection affordance can appear. Streaming answers MAY remain non-selectable until streaming completes.

树洞已完成助手答复（含 tip 注入）在长按结束后必须能形成可保持的文本选区（出现手柄或等价平台选区表现）；流式进行中可不要求可选。

#### Scenario: Selection remains after finger up

- **WHEN** 用户在已完成的助手答复上长按并松手
- **THEN** 选区高亮不因松手立即消失，且出现选区手柄或等价选区控件

#### Scenario: Tip-injected assistant uses same path

- **WHEN** 树洞展示 tip 注入的已完成助手气泡
- **THEN** 该气泡的选区行为与普通助手答复一致

### Requirement: Companion assistant selection toolbar copy

When a text selection is active on a companion assistant answer bubble, the client SHALL present a selection toolbar above the selection that includes a **「复制」** action. Activating **「复制」** MUST copy the currently selected text fragment to the system clipboard.

助手答复存在有效文本选区时，必须在选区上方展示含「复制」的工具条；点击「复制」必须把**当前选中片段**写入系统剪贴板。

#### Scenario: Copy selected fragment via toolbar

- **WHEN** 用户在助手答复上已形成文本选区，并点击选区上方工具条的「复制」
- **THEN** 剪贴板内容等于该选中片段（非强制整段气泡）

#### Scenario: Home tip stays non-selectable

- **WHEN** 用户在首页 tip 面板上操作
- **THEN** tip 正文保持不可选，行为不因本变更改变
