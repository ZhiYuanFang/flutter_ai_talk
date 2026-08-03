## ADDED Requirements

### Requirement: Tip panel MUST center as an opaque card with bottom actions

When the home tip has displayable text, the client MUST present it as a centered card over the home feed viewport with an opaque surface (no translucent alpha that reveals history through the card), and MUST place「关闭」and「对话」action controls directly below the card (not a top-trailing close icon). 当小贴士有可展示文本时，客户端 **必须** 在主页喂养可视区以**居中不透明卡片**展示，并在卡片**正下方**放置「关闭」「对话」；**不得**使用右上角关闭图标作为主关闭入口。

#### Scenario: 居中不透明与下方按钮

- **WHEN** tip 有可展示文本且面板可见
- **THEN** 卡片 MUST 大致位于屏幕/主页内容区中央
- **AND** 卡片背景 MUST 不透明（alpha 1）
- **AND** 「关闭」「对话」MUST 出现在卡片正下方
- **AND** MUST NOT 展示右上角 ✕ 关闭图标

### Requirement: Tip MUST show when thinking or answer is non-empty

The tip panel MUST become visible when either `thinking` or `answer` has non-empty trimmed text, including during `streaming` while only thinking has arrived; it MUST stay hidden when both are empty. 当 `thinking` 或 `answer` 去空白后非空时面板 **必须** 可见（含仅有思考的 streaming）；两者皆空时 **必须** 隐藏。

#### Scenario: 首段思考即显

- **WHEN** tip SSE 已进入 streaming 且 `thinking` 首次变为非空、`answer` 仍为空
- **THEN** 面板 MUST 展示并呈现思考文本

#### Scenario: 无内容不显

- **WHEN** `displayState` 为 streaming 但 thinking 与 answer 皆空
- **THEN** 面板 MUST NOT 可见占位

### Requirement: First appearance MUST use elastic scale-in

When the tip transitions from not displayable to displayable (including a replacement `startStreaming` that clears then refills content), the client MUST play a scale-from-small elastic (or equivalent spring/back) entrance animation once per such transition, unless system animations are disabled. 当 tip 从「无可展示」变为「可展示」（含替换流重置后再有内容）时，客户端 **必须** 播放一次从小变大的弹性入场（系统关闭动画时除外）。

#### Scenario: 首次有内容弹性展开

- **WHEN** 面板从隐藏变为有思考/答案内容
- **THEN** UI MUST 播放一次 scale 弹性入场

#### Scenario: 流式增量不重复入场

- **WHEN** 面板已可见且仅累积更多 thinking/answer 字符
- **THEN** MUST NOT 为每次字符增量重新播放完整入场弹性动画

### Requirement: Dismiss MUST be allowed during streaming and done

Tapping「关闭」MUST dismiss the tip while `displayState` is `streaming` or `done`, clearing the panel to a hidden idle (or equivalent) state. 在 streaming 或 done 时点击「关闭」**必须** 关闭面板并回到隐藏态。

#### Scenario: 思考中关闭

- **WHEN** tip 正在 streaming 且已展示思考文本
- **AND** 用户点击「关闭」
- **THEN** 面板 MUST 隐藏
- **AND** MUST NOT 因同一次旧流的迟到增量再次展示（须忽略或丢弃该次流）

#### Scenario: done 关闭

- **WHEN** tip 为 done 且用户点击「关闭」
- **THEN** 面板 MUST 隐藏

### Requirement: Centered tip MUST NOT block history hit-testing outside the card

While the tip card is visible, pointer events outside the card and its bottom action row MUST reach the underlying home history (and other home controls) as if the tip overlay were absent in those regions; the client MUST NOT install a full-screen modal barrier that consumes those taps. tip 可见时，卡片与下方按钮**以外**区域的点击 **必须** 穿透到历史列表等下层控件；**不得** 使用全屏模态遮罩吞掉这些点击。

#### Scenario: 点历史仍可操作

- **WHEN** tip 居中可见
- **AND** 用户点击卡片与按钮以外的历史列表区域
- **THEN** 该点击 MUST 由历史区（或原目标控件）处理

### Requirement: Replacement tip MUST refresh content and replay entrance

When tip streaming is started again while a tip is already shown (e.g. another successful button-path add), the client MUST replace displayed content with the new stream and MUST replay the elastic entrance when new displayable text arrives. 已展示 tip 时再次 `startStreaming`（如再次按钮添加成功）**必须** 替换展示内容，并在新内容可展示时**再播**入场弹性动画。

#### Scenario: 展示中新添加替换再弹

- **WHEN** 当前 tip 面板可见
- **AND** 本机再次按钮添加成功并触发新的 tip `startStreaming`
- **THEN** 面板 MUST 切换为新流内容（旧文案不得与新流永久并存为两张卡）
- **AND** 当新 thinking/answer 非空时 MUST 再播一次入场动画
